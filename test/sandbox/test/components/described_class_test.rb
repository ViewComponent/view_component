# frozen_string_literal: true

require "test_helper"

class DescribedClassTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.__vc_load_previews
  end

  def described_class
    MyComponent
  end

  def test_render_preview
    render_preview(:default)

    assert_selector("div", text: "hello,world!")
  end
end
