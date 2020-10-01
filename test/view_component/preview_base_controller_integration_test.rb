# frozen_string_literal: true

require "test_helper"

class PreviewBaseControllerIntegrationTest < ActionDispatch::IntegrationTest
  def test_that_preview_controller_defaults_to_rails_controller
    assert_equal ViewComponentsController.superclass, Rails::ApplicationController
  end

  def test_that_preview_controller_can_be_configured_to_custom_controller
    with_preview_base_controller("MyPreviewController") do
      assert_equal ViewComponentsController.superclass, MyPreviewController
    end
  end
end
