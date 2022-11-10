# frozen_string_literal: true

require "test_helper"

class RenderPreviewTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.load_previews
  end

  def test_render_preview_from_class
    render_preview(:default, from: MyComponentPreview)

    assert_selector("div", text: "hello,world!")
  end
end
