# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class ConfigTest < TestCase
    def setup
      @config = ViewComponent::Config.new
    end

    def test_defaults_are_correct
      assert_equal @config.generate, {}
      assert_equal @config.preview_controller, "ViewComponentsController"
      assert_equal @config.preview_route, "/rails/view_components"
      assert_equal @config.show_previews_source, false
      assert_equal @config.instrumentation_enabled, false
      assert_equal @config.render_monkey_patch_enabled, true
      assert_equal @config.show_previews, true
      assert_equal @config.use_global_output_buffer, false
      assert_equal @config.preview_paths, ["#{Rails.root}/test/components/previews"]
    end

    def test_preview_path_alias
      @config.preview_path << "some/new/path"
      assert_equal @config.preview_paths, @config.preview_path
    end

    def test_preview_path_setter_alias
      old_value = @config.preview_path
      @config.preview_path = "some/new/path"
      assert_equal @config.preview_path, ["some/new/path"]
      @config.preview_path = old_value
    end

    def test_all_methods_are_documented
      require 'yard'
      require 'rake'
      YARD::Rake::YardocTask.new
      Rake::Task["yard"].execute
      configuration_methods_to_document = YARD::RegistryStore.new.tap do |store|
        store.load!('.yardoc')
      end.get("ViewComponent::Config").meths.select(&:reader?)
      default_options = ViewComponent::Config.defaults.keys
      accessors = ViewComponent::Config.instance_methods(false).reject { |method_name| method_name.end_with?('=') }
      options_defined_on_instance = Set[*default_options, *accessors]
      assert (options_defined_on_instance.subset?(Set[*configuration_methods_to_document.map(&:name)])), 'Not all configuration options are documented.'
      assert configuration_methods_to_document.map(&:docstring).all?(&:present?), 'Configuration options are missing docstrings.'
    end
  end
end
