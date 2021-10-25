# frozen_string_literal: true

require "test_helper"

class ViewComponentTest < ViewComponent::TestCase
  class MyCoreComponent < ViewComponent::Core
    def call
      content_tag :div do
        "hello,world"
      end
    end
  end

  def test_render_inline
    render_inline(MyCoreComponent.new)

    assert_selector("div", text: "hello,world!")
  end
end
