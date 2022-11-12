# frozen_string_literal: true

require "test_helper"

class MyComponentTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.load_previews
  end

  def test_render_preview
    render_preview(:default)

    assert_selector("div", text: "hello,world!")
  end

  def test_render_preview_with_args
    render_preview(:with_content, params: {content: "foo"})

    assert_text("foo")
  end
end
