# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class ConfigTest < TestCase
    def setup
      @config = ViewComponent::Config.new
    end

    def test_defaults_are_correct
      assert_equal @config.generate, {preview_path: "", path: "app/components"}
      assert_equal @config.previews.controller, "ViewComponentsController"
      assert_equal @config.previews.route, "/rails/view_components"
      assert_equal @config.instrumentation_enabled, false
      assert_equal @config.previews.paths, ["#{Rails.root}/test/components/previews"]
    end

    def test_setting_documented_options_does_not_raise
      @config.instrumentation_enabled = true
      @config.previews.controller = "MyPreviewController"
      @config.previews.route = "/my_previews"
      @config.previews.enabled = false
      @config.previews.default_layout = "preview_layout"
      @config.previews.paths = []
      %i[
        path preview_path parent_class sidecar stimulus_controller typescript
        locale distinct_locale_files preview use_component_path_for_rspec_tests
      ].each { |option| @config.generate[option] = true }

      assert_equal true, @config.generate.typescript
    end

    def test_setting_an_option_renamed_in_4_0_raises
      error = assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.preview_controller = "MyPreviewController"
      end

      assert_equal(
        "`config.view_component.preview_controller` was renamed to " \
          "`config.view_component.previews.controller` in ViewComponent 4.0.",
        error.message
      )
    end

    def test_setting_an_unknown_option_with_hash_syntax_raises
      assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config[:preview_controller] = "MyPreviewController"
      end
    end

    def test_setting_a_generate_option_renamed_in_4_0_raises
      error = assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.generate.component_parent_class = "MyBaseComponent"
      end

      assert_includes error.message, "`config.view_component.generate.parent_class`"
    end

    def test_setting_an_option_removed_in_4_0_raises
      error = assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.test_controller = "MyController"
      end

      assert_equal(
        "`config.view_component.test_controller` was removed in ViewComponent 4.0. " \
          "Use the `vc_test_controller_class` test helper instead.",
        error.message
      )
    end

    def test_generate_options_do_not_use_root_rename_hints
      error = assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.generate.preview_paths = "spec/components/previews"
      end

      assert_includes error.message, "`config.view_component.generate.preview_paths` isn't a ViewComponent configuration option."
      assert_includes error.message, "Valid options are: path, preview_path, parent_class"
      refute_includes error.message, "was renamed"
    end

    def test_hash_writers_validate_keys
      %i[merge! update replace].each do |method|
        options = ViewComponent::Config.defaults
        assert_raises(ViewComponent::UnknownConfigOptionError) do
          options.public_send(method, preview_controller: "MyPreviewController")
        end
      end

      assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.store(:test_controller, "MyController")
      end
    end

    def test_hash_writers_wrap_nested_namespaces
      %i[merge! update replace store].each do |method|
        options = ViewComponent::Config.defaults
        if method == :store
          options.store("generate", {"parent_class" => "MyBaseComponent"})
        else
          assert_same options, options.public_send(method, "generate" => {"parent_class" => "MyBaseComponent"})
        end

        assert_equal "MyBaseComponent", options.generate.parent_class
        assert_equal false, options.generate.typescript
        assert_raises(ViewComponent::UnknownConfigOptionError) { options.generate.typo = true }
        assert_raises(ViewComponent::UnknownConfigOptionError) do
          if method == :store
            options.generate.store(:typo, true)
          else
            options.generate.public_send(method, typo: true)
          end
        end
      end
    end

    def test_hash_writers_reject_invalid_nested_values
      %i[merge! update replace store].each do |method|
        options = ViewComponent::Config.defaults
        [nil, {contoller: "MyPreviewController"}].each do |value|
          original = options.previews
          error = value.nil? ? TypeError : ViewComponent::UnknownConfigOptionError
          assert_raises(error) do
            if method == :store
              options.store(:previews, value)
            else
              options.public_send(method, previews: value)
            end
          end
          assert_same original, options.previews
        end
      end
    end

    def test_merge_accepts_multiple_hashes_and_a_conflict_block
      options = @config.generate
      conflicts = []
      result = options.update({"path" => "lib/components"}, {path: "other/components", sidecar: true}) do |key, old, new|
        conflicts << [key, old, new]
        "#{old}/#{new}"
      end

      assert_same options, result
      assert_equal "app/components/lib/components/other/components", options.path
      assert_equal true, options.sidecar
      assert_equal [
        [:path, "app/components", "lib/components"],
        [:path, "app/components/lib/components", "other/components"]
      ], conflicts
      assert_same options, options.merge!
      assert_raises(TypeError) { options.merge!(nil) }
      assert_raises(TypeError) { options.replace(nil) }
    end

    def test_replacing_options_validates_before_removing_existing_values
      original = @config.previews.dup

      assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.previews.replace(controller: "MyPreviewController", typo: true)
      end

      assert_equal original, @config.previews
    end

    def test_removed_namespaces_retain_their_validation_when_reassigned
      %i[clear replace delete shift].each do |method|
        options = ViewComponent::Config.defaults
        case method
        when :replace then options.replace({})
        when :delete then options.delete(:generate)
        else options.public_send(method)
        end
        replacement = {generate: {parent_class: "MyBaseComponent"}}
        options.merge!(replacement)

        assert_equal "MyBaseComponent", options.generate.parent_class
        assert_equal false, options.generate.typescript
        assert_raises(ViewComponent::UnknownConfigOptionError) { options.generate.typo = true }
      end
    end

    def test_transforming_keys_validates_new_keys
      options = @config.generate
      assert_kind_of Enumerator, options.transform_keys!
      assert_same options, options.transform_keys!(&:to_s)
      assert_raises(ViewComponent::UnknownConfigOptionError) do
        options.transform_keys!(path: :typo)
      end
      assert_equal "app/components", options.path
    end

    def test_transforming_values_preserves_nested_validation
      options = ViewComponent::Config.defaults
      assert_kind_of Enumerator, options.transform_values!
      assert_same options, options.transform_values! { |value| value.is_a?(Hash) ? value.to_h : value }
      assert_equal false, options.generate.typescript
      assert_raises(ViewComponent::UnknownConfigOptionError) { options.previews.typo = true }
      assert_raises(TypeError) { options.transform_values! { nil } }
    end

    def test_setting_a_misspelled_option_raises
      error = assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.instrumentaton_enabled = true
      end

      assert_equal(
        "`config.view_component.instrumentaton_enabled` isn't a ViewComponent configuration option. " \
          "Valid options are: generate, previews, instrumentation_enabled.",
        error.message
      )
    end

    def test_setting_a_misspelled_nested_option_raises
      error = assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.previews.contoller = "MyPreviewController"
      end

      assert_includes error.message, "`config.view_component.previews.contoller`"
    end

    def test_reading_an_unknown_option_returns_nil
      assert_nil @config.preview_controller
    end

    def test_duplicated_options_are_strict
      assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.generate.dup.component_parent_class = "MyBaseComponent"
      end
    end

    def test_generate_options_default_to_false
      assert_equal false, @config.generate.typescript
    end

    def test_replacing_nested_options_preserves_strictness
      %i[previews generate].each do |namespace|
        @config[namespace] = ActiveSupport::OrderedOptions.new

        assert_raises(ViewComponent::UnknownConfigOptionError) do
          @config[namespace].typo = true
        end
      end
      assert_equal false, @config.generate.typescript
    end

    def test_replacing_nested_options_preserves_values
      @config.previews = {"controller" => "MyPreviewController"}
      @config.generate = {parent_class: "MyBaseComponent"}

      assert_equal({controller: "MyPreviewController"}, @config.previews)
      assert_equal({parent_class: "MyBaseComponent"}, @config.generate)
      assert_equal false, @config.generate.typescript
      assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.generate.component_parent_class = "OtherComponent"
      end
    end

    def test_replacing_nested_options_rejects_unknown_keys
      original = @config.previews
      replacement = ActiveSupport::OrderedOptions.new
      replacement.contoller = "MyPreviewController"

      error = assert_raises(ViewComponent::UnknownConfigOptionError) do
        @config.previews = replacement
      end

      assert_includes error.message, "`config.view_component.previews.contoller`"
      assert_same original, @config.previews
    end

    def test_replacing_nested_options_rejects_non_hash_values
      %i[previews generate].each do |namespace|
        original = @config[namespace]
        assert_raises(TypeError) { @config[namespace] = nil }
        assert_same original, @config[namespace]
      end
    end

    def test_all_methods_are_documented
      require "yard"
      require "rake"
      YARD::Rake::YardocTask.new do |t|
        t.options = ["--no-output", "--no-stats", "--no-progress", "-q"]
      end
      Rake::Task["yard"].execute
      configuration_methods_to_document = YARD::RegistryStore.new.tap do |store|
        store.load!(".yardoc")
      end.get("ViewComponent::Config").meths.select(&:reader?).reject { |meth| meth.name == :config }
      default_options = ViewComponent::Config.defaults.keys
      accessors = ViewComponent::Config.instance_methods(false).reject do |method_name|
        method_name.to_s.end_with?("=") || method_name == :method_missing
      end
      options_defined_on_instance = Set[*default_options, *accessors]
      assert options_defined_on_instance.subset?(Set[*configuration_methods_to_document.map(&:name)]),
        "Not all configuration options are documented: #{options_defined_on_instance.to_a - configuration_methods_to_document.map(&:name)}"
      assert configuration_methods_to_document.map(&:docstring).all?(&:present?),
        "Configuration options are missing docstrings."
    end
  end
end
