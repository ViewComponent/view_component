# frozen_string_literal: true

require_relative "../test_helper"

module ViewComponent
  class ConfigTest < ActiveSupport::TestCase
    def setup
      @config = ViewComponent::Config.new
    end

    def test_defaults_are_correct
      assert_equal @config.generate, {preview_path: "", path: "app/components"}
      assert_equal @config.previews.controller, "ViewComponentsController"
      assert_equal @config.previews.route, "/rails/view_components"
      assert_equal @config.instrumentation_enabled, false
      assert_equal @config.previews.enabled, true
      assert_equal @config.previews.paths, ["#{TestEngine::Engine.root}/test/components/previews"]
    end
  end
end
