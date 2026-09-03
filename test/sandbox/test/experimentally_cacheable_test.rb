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

  # A component rendered dynamically can be declared by class name, without
  # naming the internal path it's digested under.
  def test_cache_digest_changes_when_a_component_declared_by_class_name_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableDynamicConstantComponent.cache_digest }
  end

  def test_declared_component_class_names_resolve_to_the_component
    template = build_template("<%# Template Dependency: CacheableChildComponent %>")
    dependencies = ActionView::DependencyTracker.find_dependencies("test/template", template, [])

    assert_includes dependencies, "view_component/cache_digest/cacheable_child_component"
    # The raw class name would resolve to nothing, so it's replaced rather than added.
    refute_includes dependencies, "CacheableChildComponent"
  end

  def test_declared_template_paths_are_left_alone
    template = build_template("<%# Template Dependency: integration_examples/erb_partial %>")
    dependencies = ActionView::DependencyTracker.find_dependencies("test/template", template, [])

    assert_includes dependencies, "integration_examples/erb_partial"
  end

  def test_declared_names_that_are_not_cacheable_components_are_left_alone
    assert_empty ViewComponent::CacheDigest.explicit_component_dependencies(
      "# Template Dependency: ErbComponent"
    )
    assert_empty ViewComponent::CacheDigest.explicit_component_dependencies("no declarations here")
  end

  # Components rendered from an inline template are invisible to Action View's
  # trackers, which only read template files.
  def test_cache_digest_changes_when_a_child_of_an_inline_template_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableInlineTemplateComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_partial_of_an_inline_template_changes
    assert_digest_changes(
      "app/views/integration_examples/_erb_partial.html.erb",
      "<div>changed partial</div>\n"
    ) { CacheableInlinePartialComponent.cache_digest }
  end

  # Components rendered from a `#call` method live in Ruby, not in a template.
  def test_cache_digest_changes_when_a_child_of_a_call_method_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableCallComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_call_method_child_ruby_file_changes
    original = File.read(Rails.root.join("app/components/cacheable_child_component.rb"))

    assert_digest_changes(
      "app/components/cacheable_child_component.rb",
      original + "\n# a comment\n"
    ) { CacheableCallComponent.cache_digest }
  end

  # Partials referenced by string path from Ruby are found with Rails' own
  # render parser, the same one `RubyTracker` runs over compiled templates.
  def test_cache_digest_changes_when_a_partial_of_a_call_method_changes
    assert_digest_changes(
      "app/views/integration_examples/_erb_partial.html.erb",
      "<div>changed partial</div>\n"
    ) { CacheableCallPartialComponent.cache_digest }
  end

  def test_partial_paths_are_extracted_from_ruby_source
    source = <<~RUBY
      def call
        render "posts/byline"
      end
    RUBY

    assert_equal(
      ["posts/_byline"],
      ViewComponent::CacheDigest.partial_paths_in(source, "view_component/cache_digest/post_component")
    )
  end

  # The parser speculatively infers `things/_thing` from dynamic renders. Those
  # resolve to nothing, so they're discarded rather than emitted as noise.
  def test_speculative_partial_paths_are_discarded
    source = <<~RUBY
      def call
        render @thing
        render OtherComponent.new
        render "bare_name"
      end
    RUBY

    assert_empty(
      ViewComponent::CacheDigest.partial_paths_in(source, "view_component/cache_digest/post_component")
    )
  end

  def test_partial_paths_are_not_extracted_from_sources_without_render
    assert_empty ViewComponent::CacheDigest.partial_paths_in("def call; end", "a/b")
  end

  def test_partial_path_extraction_swallows_parser_errors
    swallowing_digest_errors do |log|
      ViewComponent::CacheDigest::RENDER_PARSER.stub(:new, ->(*) { raise "boom" }) do
        assert_empty ViewComponent::CacheDigest.partial_paths_in("render \"a/b\"", "a/b")
      end

      assert_match "Ignored an error while scanning a/b for rendered partials: RuntimeError: boom", log.string
    end
  end

  def test_partial_path_extraction_raises_parser_errors_locally
    ViewComponent::CacheDigest::RENDER_PARSER.stub(:new, ->(*) { raise "boom" }) do
      error = assert_raises(RuntimeError) do
        ViewComponent::CacheDigest.partial_paths_in("render \"a/b\"", "a/b")
      end

      assert_equal "boom", error.message
    end
  end

  # Action View has shipped the parser as a class (7.1, main) and as a module
  # with a `Default` implementation (7.2 through 8.1). Exercised with doubles so
  # both shapes are covered whichever version is running.
  def test_render_parser_supports_both_action_view_shapes
    parser_class = Class.new

    assert_equal parser_class, ViewComponent::CacheDigest.resolve_render_parser(parser_class)

    default = Class.new
    parser_module = Module.new
    parser_module.const_set(:Default, default)

    assert_equal default, ViewComponent::CacheDigest.resolve_render_parser(parser_module)
  end

  def test_render_parser_is_resolved_for_the_running_action_view
    assert_respond_to ViewComponent::CacheDigest::RENDER_PARSER, :new
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
  ensure
    recompile(CacheableChildComponent)
  end

  def test_passing_a_block_to_a_cached_component_raises
    error = assert_raises(ViewComponent::ContentPassedToCachedComponentError) do
      render_inline(CacheableComponent.new(title: "a")) { "content" }
    end

    assert_includes error.message, "CacheableComponent"
  end

  def test_passing_with_content_to_a_cached_component_raises
    assert_raises(ViewComponent::ContentPassedToCachedComponentError) do
      render_inline(CacheableComponent.new(title: "a").with_content("content"))
    end
  end

  def test_setting_a_slot_on_a_cached_component_raises
    error = assert_raises(ViewComponent::ContentPassedToCachedComponentError) do
      render_inline(CacheableSlotComponent.new(title: "a").tap { |c| c.with_header { "set" } })
    end

    assert_includes error.message, "CacheableSlotComponent"
  end

  # A slot the component fills in for itself isn't caller-provided, so it's
  # part of the component's own output and safe to cache.
  def test_a_default_filled_slot_does_not_raise
    render_inline(CacheableSlotComponent.new(title: "a"))

    assert_selector(".header", text: "default header")
    assert_selector(".title", text: "a")
  end

  def test_default_filled_slots_are_cached
    with_caching do
      render_inline(CacheableSlotComponent.new(title: "cached"))

      refute_nil Rails.cache.read(
        CacheableSlotComponent.new(title: "cached").cache_key(vc_test_controller.view_context)
      )
    end
  end

  # Raised regardless of whether caching is on, so the conflict is caught in
  # development and test rather than only in production.
  def test_content_raises_even_when_caching_is_enabled
    with_caching do
      assert_raises(ViewComponent::ContentPassedToCachedComponentError) do
        render_inline(CacheableComponent.new(title: "a")) { "content" }
      end
    end
  end

  def test_components_without_cache_on_still_accept_content
    render_inline(CacheableParentComponent.new) { "content" }

    assert_selector(".cacheable-child", text: "child")
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

    swallowing_digest_errors do |log|
      ViewComponent::CacheDigest.stub(:component_for, ->(_) { raise "boom" }) do
        assert_empty resolver.find_templates("cacheable_component", "view_component/cache_digest", true, {})
      end

      assert_match(
        "Ignored an error while building the digest template for " \
          "view_component/cache_digest/cacheable_component: RuntimeError: boom",
        log.string
      )
    end
  end

  def test_resolver_raises_when_synthesis_fails_locally
    resolver = ViewComponent::CacheDigest::Resolver.instance

    ViewComponent::CacheDigest.stub(:component_for, ->(_) { raise "boom" }) do
      assert_raises(RuntimeError) do
        resolver.find_templates("cacheable_component", "view_component/cache_digest", true, {})
      end
    end
  end

  def test_dependency_tracking_falls_back_when_scanning_fails
    template = build_template("<%= render CacheableComponent.new(title: 'a') %>")

    swallowing_digest_errors do |log|
      ViewComponent::CacheDigest.stub(:dependencies_in, ->(_) { raise "boom" }) do
        refute_includes(
          ActionView::DependencyTracker.find_dependencies("some/template", template, []),
          "view_component/cache_digest/cacheable_component"
        )
      end

      assert_match "Ignored an error while tracking component dependencies in some/template", log.string
    end
  end

  def test_dependency_tracking_raises_when_scanning_fails_locally
    template = build_template("<%= render CacheableComponent.new(title: 'a') %>")

    ViewComponent::CacheDigest.stub(:dependencies_in, ->(_) { raise "boom" }) do
      assert_raises(RuntimeError) { ActionView::DependencyTracker.find_dependencies("some/template", template, []) }
    end
  end

  def test_constantizing_swallows_unexpected_errors
    with_boom_component do
      swallowing_digest_errors do |log|
        assert_nil ViewComponent::CacheDigest.send(:constantize_component, "BoomComponent")

        assert_match "Ignored an error while resolving BoomComponent: ArgumentError", log.string
      end
    end
  end

  def test_constantizing_raises_unexpected_errors_locally
    with_boom_component do
      assert_raises(ArgumentError) { ViewComponent::CacheDigest.send(:constantize_component, "BoomComponent") }
    end
  end

  def test_digest_errors_are_swallowed_without_a_logger
    without_raising_digest_errors do
      ViewComponent::CacheDigest.stub(:logger, nil) do
        assert_nil ViewComponent::CacheDigest.handle_error(RuntimeError.new("boom"), "digesting")
      end
    end
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

  # `with_new_cache` compiles components against whatever is on disk, then
  # restores the previous compile cache on exit. A component compiled while its
  # template was modified is therefore still registered as compiled, and keeps
  # rendering the modified output after the file is restored. Force it back.
  def recompile(component)
    ViewComponent::CompileCache.cache.delete(component)
    component.__vc_compile(force: true)
  end

  # The digest machinery raises in local environments, and the sandbox runs as
  # `test`, so the swallow-and-report path has to be opted into explicitly.
  def without_raising_digest_errors
    previous = ViewComponent::Base.config.raise_on_cache_digest_errors
    ViewComponent::Base.config.raise_on_cache_digest_errors = false

    yield
  ensure
    ViewComponent::Base.config.raise_on_cache_digest_errors = previous
  end

  def swallowing_digest_errors
    log = StringIO.new

    without_raising_digest_errors do
      ViewComponent::CacheDigest.stub(:logger, ActiveSupport::Logger.new(log)) { yield log }
    end
  end

  def with_boom_component
    Object.const_set(:BoomComponent, Class.new do
      def self.__vc_cacheable?
        raise ArgumentError
      end
    end)

    yield
  ensure
    Object.send(:remove_const, :BoomComponent)
  end

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
