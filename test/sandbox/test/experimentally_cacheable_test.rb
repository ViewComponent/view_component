# frozen_string_literal: true

require "test_helper"

class ExperimentallyCacheableTest < ViewComponent::TestCase
  def setup
    super
    Rails.cache.clear
  end

  def teardown
    Rails.cache.clear
    super
  end

  def test_registers_component_with_the_digest_registry
    assert_equal(
      "CacheableComponent",
      ViewComponent::CacheDigest.registry["cacheable_component"]
    )
  end

  def test_component_is_marked_cacheable
    assert_predicate CacheableComponent, :__vc_cacheable?
    refute_respond_to ErbComponent, :__vc_cacheable?
  end

  def test_cache_on_declares_key_methods
    assert_equal [:title], CacheableComponent.__vc_cache_on
  end

  def test_component_without_cache_on_does_not_cache_output
    refute_predicate CacheableParentComponent, :__vc_caches_output?
    assert_predicate CacheableComponent, :__vc_caches_output?
  end

  def test_cache_digest_is_computable_outside_a_request
    digest = CacheableComponent.cache_digest

    assert_kind_of String, digest
    refute_empty digest
  end

  def test_cache_digest_changes_when_the_template_changes
    assert_digest_changes(
      "app/components/cacheable_component.html.erb",
      "<div class=\"cacheable\">changed</div>\n"
    ) { CacheableComponent.cache_digest }
  end

  def test_cache_digest_changes_when_the_ruby_file_changes
    original = File.read(Rails.root.join("app/components/cacheable_component.rb"))

    assert_digest_changes(
      "app/components/cacheable_component.rb",
      original + "\n# a comment\n"
    ) { CacheableComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_child_component_template_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableParentComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_child_component_ruby_file_changes
    original = File.read(Rails.root.join("app/components/cacheable_child_component.rb"))

    assert_digest_changes(
      "app/components/cacheable_child_component.rb",
      original + "\n# a comment\n"
    ) { CacheableParentComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_superclass_template_changes
    assert_digest_changes(
      "app/components/cacheable_component.html.erb",
      "<div class=\"cacheable\">changed</div>\n"
    ) { CacheableSubclassComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_superclass_ruby_file_changes
    original = File.read(Rails.root.join("app/components/cacheable_component.rb"))

    assert_digest_changes(
      "app/components/cacheable_component.rb",
      original + "\n# a comment\n"
    ) { CacheableSubclassComponent.cache_digest }
  end

  def test_cache_digest_changes_when_an_explicitly_declared_dependency_changes
    assert_digest_changes(
      "app/views/integration_examples/_erb_partial.html.erb",
      "<div>changed partial</div>\n"
    ) { CacheableExplicitDependencyComponent.cache_digest }
  end

  def test_cache_digest_is_unaffected_by_unrelated_changes
    clear_digest_cache
    before = CacheableComponent.cache_digest

    modify_file "app/components/erb_component.html.erb", "<div>unrelated</div>\n" do
      clear_digest_cache

      assert_equal before, CacheableComponent.cache_digest
    end
  end

  def test_digests_of_different_components_differ
    refute_equal CacheableComponent.cache_digest, CacheableParentComponent.cache_digest
  end

  def test_cache_key_includes_cache_on_values
    a = CacheableComponent.new(title: "a").cache_key
    b = CacheableComponent.new(title: "b").cache_key

    refute_equal a, b
  end

  def test_cache_key_includes_the_digest
    key = CacheableComponent.new(title: "a").cache_key

    assert_includes key, CacheableComponent.cache_digest
  end

  def test_undefined_cache_on_method_raises
    component = Class.new(CacheableComponent) do
      cache_on :nonexistent
    end

    error = assert_raises(ViewComponent::UndefinedCacheKeyMethodError) do
      component.new(title: "a").cache_key
    end

    assert_includes error.message, "nonexistent"
  end

  def test_renders_normally_when_caching_is_disabled
    render_inline(CacheableComponent.new(title: "hello"))

    assert_selector(".cacheable", text: "hello")
  end

  def test_nothing_is_written_to_the_cache_when_caching_is_disabled
    render_inline(CacheableComponent.new(title: "hello"))

    assert_nil Rails.cache.read(CacheableComponent.new(title: "hello").cache_key(vc_test_controller.view_context))
  end

  def test_output_is_served_from_the_cache_on_a_second_render
    with_caching do
      render_inline(CacheableComponent.new(title: "first"))
      assert_selector(".cacheable", text: "first")

      # Change the template underneath a warm cache. The digest is memoized, so
      # a second render of the same key must return the cached markup.
      modify_file "app/components/cacheable_component.html.erb", "<div class=\"cacheable\">ignored</div>\n" do
        render_inline(CacheableComponent.new(title: "first"))

        assert_selector(".cacheable", text: "first")
      end
    end
  end

  def test_different_cache_on_values_produce_different_output
    with_caching do
      render_inline(CacheableComponent.new(title: "one"))
      assert_selector(".cacheable", text: "one")

      render_inline(CacheableComponent.new(title: "two"))
      assert_selector(".cacheable", text: "two")
    end
  end

  def test_cached_output_is_html_safe
    with_caching do
      render_inline(CacheableComponent.new(title: "<b>bold</b>"))
      first = page.native.to_html

      render_inline(CacheableComponent.new(title: "<b>bold</b>"))

      assert_equal first, page.native.to_html
      assert_no_selector("b")
    end
  end

  def test_components_without_cache_on_are_not_output_cached
    with_caching do
      render_inline(CacheableParentComponent.new)
      assert_selector(".cacheable-child", text: "child")

      modify_file "app/components/cacheable_child_component.html.erb", "<span class=\"cacheable-child\">changed</span>\n" do
        with_new_cache do
          render_inline(CacheableParentComponent.new)

          assert_selector(".cacheable-child", text: "changed")
        end
      end
    end
  end

  def test_content_blocks_are_not_cached
    component = Class.new(CacheableComponent) do
      def self.name
        "BlockCacheableComponent"
      end
    end

    with_caching do
      # A block's content isn't part of the cache key, so caching is skipped
      # rather than risk serving one caller's content to another.
      instance = component.new(title: "a")

      refute instance.send(:__vc_cache_enabled?, vc_test_controller.view_context, proc { "content" })
      assert instance.send(:__vc_cache_enabled?, vc_test_controller.view_context, nil)
    end
  end

  def test_anonymous_components_are_not_registered
    before = ViewComponent::CacheDigest.registry.dup

    Class.new(CacheableComponent)

    assert_equal before, ViewComponent::CacheDigest.registry
  end

  def test_virtual_path_for_returns_nil_without_a_virtual_path
    assert_nil ViewComponent::CacheDigest.virtual_path_for(Class.new(CacheableComponent))
  end

  def test_component_for_ignores_paths_outside_the_prefix
    assert_nil ViewComponent::CacheDigest.component_for("integration_examples/cached_component")
  end

  def test_component_for_returns_nil_for_unregistered_paths
    assert_nil ViewComponent::CacheDigest.component_for("view_component/cache_digest/nope")
  end

  def test_dependencies_are_not_scanned_for_sources_without_render
    assert_empty ViewComponent::CacheDigest.dependencies_in(build_template("no calls here"))
  end

  def test_dependencies_are_found_for_component_renders
    assert_equal(
      ["view_component/cache_digest/cacheable_component"],
      ViewComponent::CacheDigest.dependencies_in(build_template("<%= render CacheableComponent.new(title: 'a') %>"))
    )
  end

  def test_dependencies_ignore_components_that_did_not_opt_in
    assert_empty ViewComponent::CacheDigest.dependencies_in(build_template("<%= render ErbComponent.new(message: 'a') %>"))
  end

  def test_resolver_is_identified_by_class
    resolver = ViewComponent::CacheDigest::Resolver.instance

    assert_equal "ViewComponent::CacheDigest::Resolver", resolver.to_s
    assert_equal "ViewComponent::CacheDigest::Resolver", resolver.to_path
    assert_equal resolver, ViewComponent::CacheDigest::Resolver.new
  end

  def test_resolver_returns_no_template_when_synthesis_fails
    resolver = ViewComponent::CacheDigest::Resolver.instance

    ViewComponent::CacheDigest.stub(:component_for, ->(_) { raise "boom" }) do
      assert_empty resolver.find_templates("cacheable_component", "view_component/cache_digest", true, {})
    end
  end

  def test_dependency_tracking_falls_back_when_scanning_fails
    template = build_template("<%= render CacheableComponent.new(title: 'a') %>")

    ViewComponent::CacheDigest.stub(:dependencies_in, ->(_) { raise "boom" }) do
      refute_includes(
        ActionView::DependencyTracker.find_dependencies("some/template", template, []),
        "view_component/cache_digest/cacheable_component"
      )
    end
  end

  def test_constantizing_swallows_unexpected_errors
    Object.const_set(:BoomComponent, Class.new do
      def self.__vc_cacheable?
        raise ArgumentError
      end
    end)

    assert_nil ViewComponent::CacheDigest.send(:constantize_component, "BoomComponent")
  ensure
    Object.send(:remove_const, :BoomComponent)
  end

  def test_install_is_idempotent
    resolver_count = ActionController::Base.view_paths.count { |path| path.is_a?(ViewComponent::CacheDigest::Resolver) }

    ViewComponent::CacheDigest.install!

    assert_equal(
      resolver_count,
      ActionController::Base.view_paths.count { |path| path.is_a?(ViewComponent::CacheDigest::Resolver) }
    )
  end

  private

  def build_template(source)
    ActionView::Template.new(
      source,
      "test template",
      ActionView::Template.handler_for_extension(:erb),
      locals: [],
      format: :html,
      virtual_path: "test/template"
    )
  end

  def with_caching
    old_value = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    Rails.cache.clear
    yield
  ensure
    ActionController::Base.perform_caching = old_value
    Rails.cache.clear
  end
end
