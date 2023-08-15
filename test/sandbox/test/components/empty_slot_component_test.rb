# frozen_string_literal: true

require "test_helper"

class MyComponentTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.load_previews
  end

  def test_render_without_slot
    render_preview(:default, from: EmptySlotComponent)

    assert_selector("span", text: "Hello")
  end
end
