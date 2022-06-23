# frozen_string_literal: true

require "test_helper"

class DelegateRenderTest < ViewComponent::TestCase
  def test_delegates_render
    render_inline(DelegatedRenderChildComponent.new) { "content" }

    assert_selector "p", text: "parent"
    assert_selector "p", text: "content"
  end
end
