# frozen_string_literal: true

require "test_helper"

class CacheableTest < ViewComponent::TestCase
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

  # Registration runs on every class load, so an unchanged component must not
  # throw away digests other templates are still using.
  def test_registering_an_unchanged_component_leaves_memoized_digests_alone
    clear_digest_cache
    CacheableComponent.cache_digest
    memoized = digest_cache_size

    assert_operator memoized, :>, 0

    ViewComponent::CacheDigest.register(CacheableComponent)

    assert_equal memoized, digest_cache_size
  end

  def test_registering_a_new_component_expires_memoized_digests
    clear_digest_cache
    CacheableComponent.cache_digest

    assert_operator digest_cache_size, :>, 0

    ViewComponent::CacheDigest.registry.delete("cacheable_component")
    ViewComponent::CacheDigest.register(CacheableComponent)

    assert_equal 0, digest_cache_size
  end

  def test_only_components_declaring_cache_on_cache_their_output
    assert_predicate CacheableComponent, :__vc_caches_output?
    refute_predicate ErbComponent, :__vc_caches_output?
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

  def test_cache_digest_raises_when_a_ruby_dependency_fails_to_load
    error = assert_raises(RuntimeError) { CacheableRaisingRubyDependencyComponent.cache_digest }

    assert_equal "raising Ruby dependency", error.message
  end

  def test_cache_digest_raises_when_a_template_dependency_fails_to_load
    error = assert_raises(RuntimeError) { CacheableRaisingTemplateDependencyComponent.cache_digest }

    assert_equal "raising template dependency", error.message
  end

  def test_cache_digest_raises_when_an_explicit_dependency_fails_to_load
    error = assert_raises(RuntimeError) { CacheableRaisingExplicitDependencyComponent.cache_digest }

    assert_equal "raising Ruby dependency", error.message
  end

  def test_cache_digest_raises_when_a_digest_source_cannot_be_read
    error = assert_raises(Errno::EISDIR) { CacheableUnreadableDigestSourceComponent.cache_digest }

    assert_includes error.message, "cacheable_unreadable_digest_source_component.yml"
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

  def test_cache_digest_changes_when_an_untracked_child_template_changes
    assert_digest_changes(
      "app/components/untracked_child_component.html.erb",
      "<span class=\"untracked-child\">changed</span>\n"
    ) { CacheableUntrackedParentComponent.cache_digest }
  end

  def test_cache_digest_changes_when_an_untracked_child_ruby_file_changes
    original = File.read(Rails.root.join("app/components/untracked_child_component.rb"))

    assert_digest_changes(
      "app/components/untracked_child_component.rb",
      original + "\n# a comment\n"
    ) { CacheableUntrackedParentComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_transitive_untracked_dependency_changes
    refute_predicate UntrackedChildComponent, :__vc_caches_output?
    refute_predicate HTTPUntrackedComponent, :__vc_caches_output?

    assert_digest_changes(
      "app/components/http_untracked_component.html.erb",
      "<span class=\"http-untracked\">changed</span>\n"
    ) { CacheableUntrackedParentComponent.cache_digest }
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

  def test_declared_names_that_are_not_components_are_left_alone
    assert_empty ViewComponent::CacheDigest.explicit_component_dependencies(
      "# Template Dependency: NotAConstantAnywhere"
    )
    assert_empty ViewComponent::CacheDigest.explicit_component_dependencies(
      "# Template Dependency: ActiveSupport::Digest"
    )
    assert_empty ViewComponent::CacheDigest.explicit_component_dependencies("no declarations here")
  end

  def test_declared_components_resolve_without_opting_into_caching
    refute_predicate ErbComponent, :__vc_caches_output?

    with_registry("cacheable_component" => "CacheableComponent") do
      template = build_template("<%# Template Dependency: ErbComponent %>")
      dependencies = ActionView::DependencyTracker.find_dependencies("test/template", template, [])

      assert_includes dependencies, "view_component/cache_digest/erb_component"
      refute_includes dependencies, "ErbComponent"
      assert_equal ErbComponent, ViewComponent::CacheDigest.component_for("view_component/cache_digest/erb_component")
    end
  end

  def test_cache_digest_changes_when_a_declared_untracked_component_changes
    assert_digest_changes(
      "app/components/erb_component.html.erb",
      "<div>changed</div>\n"
    ) { CacheablePlainDependencyComponent.cache_digest }
  end

  def test_declared_components_register_acronym_names_and_custom_virtual_paths
    with_registry("cacheable_component" => "CacheableComponent") do
      dependencies = ViewComponent::CacheDigest.explicit_component_dependencies(
        "# Template Dependency: HTTPUntrackedComponent\n# Template Dependency: UntrackedChildComponent"
      )

      assert_equal(
        [
          ["HTTPUntrackedComponent", "view_component/cache_digest/http_untracked_component"],
          ["UntrackedChildComponent", "view_component/cache_digest/custom/untracked_child"]
        ],
        dependencies
      )
      assert_equal HTTPUntrackedComponent,
        ViewComponent::CacheDigest.component_for("view_component/cache_digest/http_untracked_component")
      assert_equal UntrackedChildComponent,
        ViewComponent::CacheDigest.component_for("view_component/cache_digest/custom/untracked_child")
    end
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

  def test_cache_digest_changes_when_a_child_of_a_haml_template_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableHamlComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_child_of_a_slim_template_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableSlimComponent.cache_digest }
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

  def test_cache_digest_changes_when_a_component_a_slot_is_declared_with_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableSlotClassComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_component_a_slot_names_changes
    assert_digest_changes(
      "app/components/http_untracked_component.html.erb",
      "<span class=\"http-untracked\">changed</span>\n"
    ) { CacheableSlotClassNameComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_component_a_polymorphic_slot_names_changes
    assert_digest_changes(
      "app/components/untracked_child_component.html.erb",
      "<span class=\"untracked-child\">changed</span>\n"
    ) { CacheableSlotClassNameComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_component_built_by_a_method_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableMethodBuiltComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_component_assigned_to_a_local_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableLocalAliasComponent.cache_digest }
  end

  def test_cache_digest_changes_when_an_included_module_changes
    original = File.read(Rails.root.join("app/helpers/cacheable_child_helper.rb"))

    assert_digest_changes(
      "app/helpers/cacheable_child_helper.rb",
      original + "\n# a comment\n"
    ) { CacheableHelperComponent.cache_digest }
  end

  def test_cache_digest_changes_when_a_component_an_included_module_renders_changes
    assert_digest_changes(
      "app/components/cacheable_child_component.html.erb",
      "<span class=\"cacheable-child\">changed</span>\n"
    ) { CacheableHelperComponent.cache_digest }
  end

  # Every component includes modules from ViewComponent itself, which would
  # otherwise tie every digest to the installed version of the gem.
  def test_modules_view_component_includes_are_not_digested
    source = ViewComponent::CacheDigest::Resolver.instance.source_for(CacheableComponent)

    assert_includes source, "app/components/cacheable_component.rb"
    refute_includes source, ViewComponent::CacheDigest::Resolver::VIEW_COMPONENT_LIB
  end

  # A component names itself and its superclass in its own source, but both
  # are digested as part of it already.
  def test_a_component_does_not_depend_on_itself_or_its_superclasses
    source = ViewComponent::CacheDigest::Resolver.instance.source_for(CacheableSubclassComponent)

    refute_includes source, "Template Dependency: view_component/cache_digest/cacheable_component"
    refute_includes source, "Template Dependency: view_component/cache_digest/cacheable_subclass_component"
  end

  def test_components_referenced_outside_render_calls_are_found_in_ruby_source
    source = <<~RUBY
      renders_one :header, CacheableChildComponent

      def row
        ::ErbComponent.new(message: "a")
      end

      def size
        CacheableComponent::SIZES.fetch(@size, IntegrationExamplesController) || self.class::Missing
      end
    RUBY

    assert_equal(
      [
        [
          "view_component/cache_digest/cacheable_child_component",
          "view_component/cache_digest/erb_component",
          "view_component/cache_digest/cacheable_component"
        ],
        []
      ],
      ViewComponent::CacheDigest.renders_in(source, "view_component/cache_digest/post_component")
    )
  end

  def test_partial_paths_are_extracted_from_ruby_source
    source = <<~RUBY
      def call
        render "posts/byline"
      end
    RUBY

    assert_equal(
      [[], ["posts/byline"]],
      ViewComponent::CacheDigest.renders_in(source, "view_component/cache_digest/post_component")
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
      ViewComponent::CacheDigest::Resolver.instance.send(:ruby_dependencies, source, "view_component/cache_digest/post_component")
    )
  end

  def test_partial_paths_are_not_extracted_from_sources_without_render
    assert_equal [[], []], ViewComponent::CacheDigest.renders_in("def call; end", "a/b")
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

  # A `cache` block in a component template is digested from the component's
  # own path, which resolves to no template: component templates aren't in the
  # view paths. Without a digest of its own the fragment never invalidates.
  def test_a_cache_block_in_a_component_template_is_digested
    refute_predicate CacheBlockComponent, :__vc_caches_output?

    with_caching do
      key = capture_fragment_key { render_inline(CacheBlockComponent.new) }

      assert_equal(
        [:views, "cache_block_component:#{CacheBlockComponent.cache_digest}", "cache-block-fragment"],
        key
      )
    end
  end

  # A subclass renders its parent's template, so the digest has to come from the
  # component being rendered rather than from whichever class owns the file.
  # Otherwise the two share a fragment despite having different digests.
  def test_a_subclass_rendering_an_inherited_template_uses_its_own_digest
    with_caching do
      key = capture_fragment_key { render_inline(CacheBlockSubclassComponent.new) }

      assert_equal(
        [
          :views,
          "cache_block_subclass_component:#{CacheBlockSubclassComponent.cache_digest}",
          "cache-block-fragment"
        ],
        key
      )
    end
  end

  # A `cache` block in a partial the component renders is Rails' business, not
  # ours: the partial resolves through the view paths like any other template.
  def test_digest_path_for_anything_else_is_left_to_rails
    component = CacheBlockComponent.new
    render_inline(component)
    template = build_template("", virtual_path: "integration_examples/_erb_partial")

    assert_equal(
      "integration_examples/_erb_partial:#{digest_of("integration_examples/_erb_partial")}",
      component.digest_path_from_template(template)
    )
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
    assert_empty component_dependencies_in(build_template("no calls here"))
  end

  def test_dependencies_are_found_for_component_renders
    assert_equal(
      ["view_component/cache_digest/cacheable_component"],
      component_dependencies_in(build_template("<%= render CacheableComponent.new(title: 'a') %>"))
    )
  end

  def test_template_dependencies_reuse_sources_compiled_at_boot
    template = build_template("<%= render 'posts/byline' %>")

    compiled = ViewComponent::CacheDigest.retaining_compiled_sources do
      ViewComponent::CacheDigest.compiled(template.handler, template.source, "precompiled")
      ViewComponent::CacheDigest.compiled_source(template)
    end

    assert_equal "precompiled", compiled
    refute_equal "precompiled", ViewComponent::CacheDigest.compiled_source(template)
  end

  def test_dependencies_are_found_for_components_that_did_not_opt_in
    assert_equal(
      ["view_component/cache_digest/erb_component"],
      component_dependencies_in(build_template("<%= render ErbComponent.new(message: 'a') %>"))
    )
  end

  def test_discovered_components_register_acronym_names_and_custom_virtual_paths
    with_registry("cacheable_component" => "CacheableComponent") do
      dependencies = component_dependencies_in(
        build_template("<%= render HTTPUntrackedComponent.new %><%= render UntrackedChildComponent.new %>")
      )

      assert_equal(
        ["view_component/cache_digest/http_untracked_component", "view_component/cache_digest/custom/untracked_child"],
        dependencies
      )
      assert_equal "HTTPUntrackedComponent", ViewComponent::CacheDigest.registry["http_untracked_component"]
      assert_equal "UntrackedChildComponent", ViewComponent::CacheDigest.registry["custom/untracked_child"]
      assert_equal HTTPUntrackedComponent,
        ViewComponent::CacheDigest.component_for("view_component/cache_digest/http_untracked_component")
      assert_equal UntrackedChildComponent,
        ViewComponent::CacheDigest.component_for("view_component/cache_digest/custom/untracked_child")
      refute_predicate HTTPUntrackedComponent, :__vc_caches_output?
      refute_predicate UntrackedChildComponent, :__vc_caches_output?
    end
  end

  def test_dependencies_ignore_constants_that_are_not_components
    assert_empty component_dependencies_in(build_template("<%= render IntegrationExamplesController %>"))
  end

  def test_dependency_discovery_works_without_any_registered_components
    with_registry({}) do
      source = "<%# Template Dependency: UntrackedChildComponent %><%= render HTTPUntrackedComponent.new %>"
      dependencies = ActionView::DependencyTracker.find_dependencies("test/template", build_template(source), [])

      assert_includes dependencies, "view_component/cache_digest/http_untracked_component"
      assert_includes dependencies, "view_component/cache_digest/custom/untracked_child"
      refute_predicate HTTPUntrackedComponent, :__vc_caches_output?
      refute_predicate UntrackedChildComponent, :__vc_caches_output?
    end
  end

  # Action View reads `render Foo.new` as a dynamic render of a partial named
  # after the last method, inferring `news/new`. That partial doesn't exist.
  def test_templates_without_constant_renders_are_not_compiled
    ViewComponent::CacheDigest.stub(:compiled_source, ->(*) { flunk "compiled the template" }) do
      ActionView::DependencyTracker.find_dependencies(
        "test/template", build_template(%(<%= render "posts/byline" %><%= render @post %>)), []
      )
    end

    [
      "<%= render CacheableComponent.new(title: 'x') %>",
      "<%= render(\n  ::CacheableComponent.new(title: 'x')) %>",
      "<%= render_to_string CacheableComponent.new(title: 'x') %>"
    ].each do |source|
      assert_match ViewComponent::CacheDigest::CONSTANT_RENDER, source
    end
  end

  def test_partials_inferred_from_component_renders_are_discarded
    source = <<~ERB
      <%= render ErbComponent.new(message: "a") %>
      <%= render(CacheableComponent.with_collection([])) %>
      <%= render "integration_examples/erb_partial" %>
    ERB

    each_render_tracker do
      dependencies = ActionView::DependencyTracker.find_dependencies("test/template", build_template(source), [])

      assert_equal(
        [
          "integration_examples/erb_partial",
          "view_component/cache_digest/erb_component",
          "view_component/cache_digest/cacheable_component"
        ],
        dependencies
      )
    end
  end

  def test_partials_named_like_inferred_component_partials_are_kept
    source = <<~ERB
      <%= render ErbComponent.new(message: "a") %>
      <%= render "news/new" %>
    ERB

    each_render_tracker do
      dependencies = ActionView::DependencyTracker.find_dependencies("test/template", build_template(source), [])

      assert_equal ["news/new", "view_component/cache_digest/erb_component"], dependencies
    end
  end

  def test_unopted_component_digest_is_computable_without_registration
    with_registry({}) do
      refute_predicate UntrackedChildComponent, :__vc_caches_output?

      refute_empty UntrackedChildComponent.cache_digest
      assert_equal "UntrackedChildComponent", ViewComponent::CacheDigest.registry["custom/untracked_child"]
    end
  end

  def test_precompute_serves_digests_without_reading_source_files
    components = [CacheableParentComponent, CacheableChildComponent]
    clear_digest_cache
    expected = CacheableParentComponent.cache_digest
    clear_digest_cache

    ViewComponent::CacheDigest.precompute!(components)

    assert_equal ViewComponent::CacheDigest::Resolver.instance.source_for(CacheableChildComponent),
      CacheableChildComponent.__vc_cache_digest_source
    assert_predicate CacheableChildComponent.__vc_cache_digest_source, :frozen?

    finder = ActionView::LookupContext.new(ActionController::Base.view_paths, formats: [:html])
    assert_equal expected, finder.digest_cache["view_component/cache_digest/cacheable_parent_component.html"]

    # Rebuilding the tree uses the stored sources rather than the files on disk.
    clear_digest_cache
    File.stub(:read, ->(*) { flunk "read a source file" }) do
      assert_equal expected, CacheableParentComponent.cache_digest
    end
  ensure
    components.each { |component| component.__vc_cache_digest_source = nil }
    clear_digest_cache
  end

  def test_a_digest_builds_the_source_of_a_component_it_reaches_twice_once
    resolver = ViewComponent::CacheDigest::Resolver.instance
    source_for = resolver.method(:source_for)
    built = Hash.new(0)
    clear_digest_cache

    counting = lambda do |component|
      built[component] += 1
      source_for.call(component)
    end
    resolver.stub(:source_for, counting) { CacheableSharedChildComponent.cache_digest }

    assert_equal 1, built[CacheableChildComponent]
  ensure
    clear_digest_cache
  end

  # Precomputing builds a digest tree for every component, and most of those
  # trees reach the same dependencies.
  def test_precompute_shares_the_node_of_a_dependency_between_trees
    components = [CacheableSharedChildComponent, CacheableParentComponent, CacheableCallComponent, CacheableChildComponent]
    resolver = ViewComponent::CacheDigest::Resolver.instance
    find_templates = resolver.method(:find_templates)
    lookups = 0
    clear_digest_cache

    counting = lambda do |name, *args|
      lookups += 1 if name == "cacheable_child_component"
      find_templates.call(name, *args)
    end
    resolver.stub(:find_templates, counting) { ViewComponent::CacheDigest.precompute!(components) }

    # Once for the node every tree that renders the child shares, and once for
    # the child's own tree.
    assert_equal 2, lookups
  ensure
    components.each { |component| component.__vc_cache_digest_source = nil }
    clear_digest_cache
  end

  def test_resolver_is_identified_by_class
    resolver = ViewComponent::CacheDigest::Resolver.instance

    assert_equal "ViewComponent::CacheDigest::Resolver", resolver.to_s
    assert_equal "ViewComponent::CacheDigest::Resolver", resolver.to_path
    assert_equal resolver, ViewComponent::CacheDigest::Resolver.new
  end

  def test_install_is_idempotent
    ViewComponent::CacheDigest.install!

    assert_equal(
      1,
      ActionView::Digestor.singleton_class.ancestors.count(ViewComponent::CacheDigest::DigestorLookup)
    )
  end

  def test_install_leaves_view_paths_alone
    ViewComponent::CacheDigest.install!

    assert ActionController::Base.view_paths.all? { |path| path.is_a?(ActionView::FileSystemResolver) }
  end

  private

  def with_registry(entries)
    saved = ViewComponent::CacheDigest.registry.dup
    ViewComponent::CacheDigest.registry.replace(entries)
    yield
  ensure
    ViewComponent::CacheDigest.registry.replace(saved)
    clear_digest_cache
  end

  # `with_new_cache` compiles components against whatever is on disk, then
  # restores the previous compile cache on exit. A component compiled while its
  # template was modified is therefore still registered as compiled, and keeps
  # rendering the modified output after the file is restored. Force it back.
  def recompile(component)
    ViewComponent::CompileCache.cache.delete(component)
    component.__vc_compile(force: true)
  end

  # Every digest Action View has memoized, across all details keys.
  def digest_cache_size
    ActionView::LookupContext::DetailsKey.digest_caches.sum(&:size)
  end

  def component_dependencies_in(template)
    ViewComponent::CacheDigest.renders_in(ViewComponent::CacheDigest.compiled_source(template), "test/template").first
  end

  def build_template(source, virtual_path: "test/template")
    ActionView::Template.new(
      source,
      "test template",
      ActionView::Template.handler_for_extension(:erb),
      locals: [],
      format: :html,
      virtual_path: virtual_path
    )
  end

  # Run the block under both of Action View's ERB trackers.
  def each_render_tracker
    handler = ActionView::Template.handler_for_extension(:erb)
    trackers = ActionView::DependencyTracker.instance_variable_get(:@trackers)
    original = trackers[handler]

    # Rails 7.1 names the Ruby tracker `RipperTracker`.
    ruby_tracker = %i[RubyTracker RipperTracker].find { ActionView::DependencyTracker.const_defined?(_1) }

    [:ERBTracker, ruby_tracker].each do |name|
      tracker = ActionView::DependencyTracker.const_get(name)
      ActionView::DependencyTracker.register_tracker(:erb, tracker)
      yield
    end
  ensure
    trackers[handler] = original
  end

  def digest_of(virtual_path)
    ActionView::Digestor.digest(
      name: virtual_path,
      format: :html,
      finder: ActionView::LookupContext.new(ActionController::Base.view_paths)
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
