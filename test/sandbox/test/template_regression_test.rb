# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module TemplateRegressionFixtures
end

class TemplateRegressionTest < ViewComponent::TestCase
  def test_ordered_format_fallbacks_do_not_share_output_cache
    with_component_files(
      "formats_component.rb" => <<~RUBY,
        class TemplateRegressionFixtures::FormatsComponent < ViewComponent::Base
          cache_on :identity
          def identity = "same"
        end
      RUBY
      "formats_component.html.erb" => "HTML fallback",
      "formats_component.html+json.erb" => "HTML JSON variant",
      "formats_component.json.erb" => '{"format":"JSON fallback"}'
    ) do
      with_caching do
        context = vc_test_controller.view_context
        context.lookup_context.formats = [:xml, :html, :json]
        assert_includes TemplateRegressionFixtures::FormatsComponent.new.render_in(context), "HTML fallback"

        context.lookup_context.formats = [:xml, :json, :html]
        assert_includes TemplateRegressionFixtures::FormatsComponent.new.render_in(context), "JSON fallback"

        context.lookup_context.formats = [:html, :json]
        assert_includes TemplateRegressionFixtures::FormatsComponent.new.render_in(context), "HTML fallback"

        context.lookup_context.formats = [:html]
        context.lookup_context.variants = [:json]
        assert_includes TemplateRegressionFixtures::FormatsComponent.new.render_in(context), "HTML JSON variant"
      end
    end
  end

  def test_inherited_template_digest_tracks_its_defining_class
    with_component_files(
      "parent_component.rb" => "class TemplateRegressionFixtures::ParentComponent < ViewComponent::Base; end",
      "parent_component.html.erb" => "<%= render BadgeComponent.new %>",
      "parent_component/badge_component.rb" => "class TemplateRegressionFixtures::ParentComponent::BadgeComponent < ViewComponent::Base; end",
      "parent_component/badge_component.html.erb" => "parent badge",
      "child_component.rb" => "class TemplateRegressionFixtures::ChildComponent < TemplateRegressionFixtures::ParentComponent; end",
      "child_component/badge_component.rb" => "class TemplateRegressionFixtures::ChildComponent::BadgeComponent < ViewComponent::Base; end",
      "child_component/badge_component.html.erb" => "shadowed child badge"
    ) do |directory|
      component = TemplateRegressionFixtures::ChildComponent
      assert_includes component.new.render_in(vc_test_controller.view_context), "parent badge"
      before = component.cache_digest

      File.write(File.join(directory, "parent_component/badge_component.html.erb"), "changed parent badge")
      ViewComponent::CompileCache.invalidate!
      clear_digest_cache

      assert_includes component.new.render_in(vc_test_controller.view_context), "changed parent badge"
      refute_equal before, component.cache_digest
    end
  end

  def test_relative_partial_edits_change_component_digest
    with_component_files(
      "relative_partial_component.rb" => <<~RUBY,
        class TemplateRegressionFixtures::RelativePartialComponent < ViewComponent::Base
          def call
            render "heading"
          end
        end
      RUBY
      "views/examples/_heading.html.erb" => "original partial"
    ) do |directory|
      vc_test_controller.prepend_view_path(File.join(directory, "views"))
      context = vc_test_controller.view_context
      context.lookup_context.prefixes = ["examples"]
      component = TemplateRegressionFixtures::RelativePartialComponent
      assert_includes component.new.render_in(context), "original partial"
      before = component.cache_digest(finder: ActionView::LookupContext.new(context.lookup_context.view_paths))

      File.write(File.join(directory, "views/examples/_heading.html.erb"), "changed partial")
      context.lookup_context.view_paths.each(&:clear_cache)
      clear_digest_cache

      assert_includes component.new.render_in(context), "changed partial"
      refute_equal before, component.cache_digest(finder: ActionView::LookupContext.new(context.lookup_context.view_paths))
    end
  end

  def test_variant_named_after_a_format_uses_its_own_template
    with_component_files(
      "format_variant_component.rb" => "class TemplateRegressionFixtures::FormatVariantComponent < ViewComponent::Base; end",
      "format_variant_component.html.erb" => "default HTML",
      "format_variant_component.html+text.erb" => "<strong>HTML text variant</strong>",
      "format_variant_component.text.erb" => "plain text format",
      "inherited_format_variant_component.rb" => "class TemplateRegressionFixtures::InheritedFormatVariantComponent < TemplateRegressionFixtures::FormatVariantComponent; end"
    ) do
      [TemplateRegressionFixtures::FormatVariantComponent, TemplateRegressionFixtures::InheritedFormatVariantComponent].each do |component|
        context = vc_test_controller.view_context
        context.lookup_context.variants = []
        context.lookup_context.formats = [:text]
        assert_includes component.new.render_in(context), "plain text format"

        context.lookup_context.formats = [:html]
        assert_includes component.new.render_in(context), "default HTML"
        context.lookup_context.variants = [:text]
        assert_includes component.new.render_in(context), "HTML text variant"

        ViewComponent::CompileCache.invalidate!
        assert_includes component.new.render_in(context), "HTML text variant"
      end
    end
  end

  def test_precomputed_sources_track_relative_template_partials_in_every_directory
    with_component_files(
      "relative_template_component.rb" => "class TemplateRegressionFixtures::RelativeTemplateComponent < ViewComponent::Base; end",
      "relative_template_component.html.erb" => '<%= render "heading" %>',
      "views/first/_heading.html.erb" => "first partial",
      "views/second/_heading.html.erb" => "second partial",
      "views/examples/page.html.erb" => "<%= render TemplateRegressionFixtures::RelativeTemplateComponent.new %>"
    ) do |directory|
      component = TemplateRegressionFixtures::RelativeTemplateComponent
      component.__vc_cache_digest_source = ViewComponent::CacheDigest::Resolver.instance.source_for(component).freeze
      vc_test_controller.prepend_view_path(File.join(directory, "views"))
      context = vc_test_controller.view_context

      %w[first second].each do |prefix|
        context.lookup_context.prefixes = [prefix]
        assert_includes component.new.render_in(context), "#{prefix} partial"
        before = ActionView::Digestor.digest(
          name: "examples/page", format: :html,
          finder: ActionView::LookupContext.new(context.lookup_context.view_paths)
        )

        File.write(File.join(directory, "views/#{prefix}/_heading.html.erb"), "changed #{prefix} partial")
        context.lookup_context.view_paths.each(&:clear_cache)
        clear_digest_cache

        assert_includes component.new.render_in(context), "changed #{prefix} partial"
        after = ActionView::Digestor.digest(
          name: "examples/page", format: :html,
          finder: ActionView::LookupContext.new(context.lookup_context.view_paths)
        )
        refute_equal before, after
      end
    end
  end

  def test_render_parent_preserves_child_fragment_cache_identity
    with_component_files(
      "fragment_parent_component.rb" => "class TemplateRegressionFixtures::FragmentParentComponent < ViewComponent::Base; end",
      "fragment_parent_component.html.erb" => '<% cache "shared-child-fragment" do %><p><%= self.class.name %></p><% end %>',
      "first_child_component.rb" => "class TemplateRegressionFixtures::FirstChildComponent < TemplateRegressionFixtures::FragmentParentComponent; end",
      "first_child_component.html.erb" => '<% render_parent %><% cache "shared-child-fragment" do %><strong>first child</strong><% end %>',
      "second_child_component.rb" => "class TemplateRegressionFixtures::SecondChildComponent < TemplateRegressionFixtures::FragmentParentComponent; end",
      "second_child_component.html.erb" => '<% render_parent %><% cache "shared-child-fragment" do %><strong>second child</strong><% end %>'
    ) do
      with_caching do
        context = vc_test_controller.view_context
        first = TemplateRegressionFixtures::FirstChildComponent.new.render_in(context)
        assert_includes first, "first child"
        assert_includes first, "FirstChildComponent"

        second = TemplateRegressionFixtures::SecondChildComponent.new.render_in(context)
        assert_includes second, "second child"
        assert_includes second, "SecondChildComponent"
        refute_includes second, "FirstChildComponent"
      end
    end
  end

  private

  def with_component_files(files)
    Dir.mktmpdir do |directory|
      files.each do |name, source|
        path = File.join(directory, name)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, source)
      end
      files.each_key { |name| load File.join(directory, name) if name.end_with?(".rb") }
      clear_digest_cache
      yield directory
    end
  ensure
    TemplateRegressionFixtures.constants(false).each { |name| TemplateRegressionFixtures.send(:remove_const, name) }
    ViewComponent::CompileCache.invalidate!
    clear_digest_cache
  end

  def with_caching
    old_store = Rails.cache
    old_controller_store = vc_test_controller.cache_store
    old_caching = ActionController::Base.perform_caching
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    vc_test_controller.cache_store = Rails.cache
    ActionController::Base.perform_caching = true
    yield
  ensure
    Rails.cache = old_store
    vc_test_controller.cache_store = old_controller_store
    ActionController::Base.perform_caching = old_caching
  end
end
