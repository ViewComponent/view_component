# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class ConfigTest < TestCase
    def setup
      @config = ViewComponent::Config.new
    end

    def test_defaults_are_correct
      assert_equal @config.generate, {preview_path: ""}
      assert_equal @config.preview_controller, "ViewComponentsController"
      assert_equal @config.preview_route, "/rails/view_components"
      assert_equal @config.show_previews_source, false
      assert_equal @config.instrumentation_enabled, false
      assert_equal @config.use_deprecated_instrumentation_name, true
      assert_equal @config.render_monkey_patch_enabled, true
      assert_equal @config.show_previews, true
      assert_equal @config.preview_paths, ["#{Dummy::Engine.root}/test/components/previews/dummy"]
    end
  end
end
