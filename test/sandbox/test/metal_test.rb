# frozen_string_literal: true

require "test_helper"

class MetalTest < ViewComponent::TestCase
  test "it works" do
    render_inline MetalComponent.new

    assert_selector "button > span > strong"
    assert_text "Hello World"
  end
end
