# frozen_string_literal: true

require "test_helper"

class RenderMonkeyPatchDisabledIntegrationTest < ActionDispatch::IntegrationTest
  if Rails.version.to_f < 6.1 && !Rails.application.config.view_component.render_monkey_patch_enabled
    test "does not include render monkey patches if render_monkey_patch_enabled config is set to false" do
      assert(defined?(ViewComponent::RenderMonkeyPatch).nil?)
      assert(defined?(ViewComponent::RenderingMonkeyPatch).nil?)
      assert(defined?(ViewComponent::RenderToStringMonkeyPatch).nil?)
    end

    test "rendering component using the render_component helper" do
      get "/render_component"
      assert_includes response.body, "bar"
    end

    test "rendering component in a controller" do
      get "/controller_inline_render_component"
      assert_select("div", "bar")
      assert_response :success

      inline_response = response.body

      assert_includes inline_response, "<div>bar</div>"
    end

    test "rendering component in a controller using #render_to_string" do
      get "/controller_to_string_render_component"
      assert_select("div", "bar")
      assert_response :success

      to_string_response = response.body

      assert_includes to_string_response, "<div>bar</div>"
    end
  end
end
