# frozen_string_literal: true

require "test_helper"

# Regression test for GHSA-7f3r-gwc9-2995:
# The preview route derived an example name from the URL and called it with
# `public_send` without verifying the method was an explicitly declared preview
# example. This allowed inherited methods like `render_with_template` to be
# invoked via the preview route, letting an attacker render arbitrary internal
# Rails templates with attacker-controlled locals and request parameters.
class SecurityPreviewTemplatePocTest < ActionDispatch::IntegrationTest
  def setup
    ViewComponent::Preview.__vc_load_previews
  end

  def test_preview_route_cannot_invoke_inherited_render_with_template
    # `render_with_template` is inherited from ViewComponent::Preview, not
    # explicitly defined as an example on MyComponentPreview.
    refute_includes MyComponentPreview.examples, "render_with_template"

    # Before the fix, this request would succeed and render internal/secret
    # with attacker-controlled locals and request params.
    get(
      "/rails/view_components/my_component/render_with_template",
      params: {
        template: "internal/secret",
        locals: {poc_local: "attacker-controlled-local"},
        request_marker: "attacker-controlled-request"
      }
    )

    assert_response :not_found
  end
end
