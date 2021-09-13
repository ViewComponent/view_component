# frozen_string_literal: true

require "test_helper"

class ViewComponentMultipleFormatsTest < ViewComponent::TestCase
  def test_render_html
    render_inline(MyComponentMultipleFormat.new, format: :html)

    assert_selector("div", text: "hello,world!")
  end

  def test_render_text
    render_inline(MyComponentMultipleFormat.new, format: :text)

    assert_text("Hello, text world!")
  end
end
