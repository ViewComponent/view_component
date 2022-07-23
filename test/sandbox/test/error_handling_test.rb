# frozen_string_literal: true

require "test_helper"

class ErrorHandlingTest < ViewComponent::TestCase
  def test_error_handling
    render_inline(FailingComponent.new)

    assert_text("Something bad happened")
  end

  def test_error_handling_within_slot
    render_inline(FailingComponentWithSlot.new) do |c|
      c.with_body do
        10 / 0
      end
    end

    assert_text("Something bad happened")
  end

  def test_error_handling_inline
    render_inline(FailingComponentInline.new)

    assert_text("Something bad happened")
  end

  def test_error_handling_with_content
    render_inline(FailingComponentWithContent.new) do
      10 / 0
    end

    assert_text("Something bad happened")
  end
end
