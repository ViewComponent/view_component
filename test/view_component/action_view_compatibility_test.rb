# frozen_string_literal: true

require "test_helper"

class ViewComponent::ActionViewCompatibilityTest < ViewComponent::TestCase
  def test_renders_form_for_labels_with_block_correctly
    render_inline(FormForComponent.new)

    assert_selector("form > div > label > input")
    refute_selector("form > div > input")
  end

  def test_renders_form_with_labels_with_block_correctly
    render_inline(FormForComponent.new)

    assert_selector("form > div > label > input")
    refute_selector("form > div > input")
  end

  def test_form_without_compatability_does_not_raise
    render_inline(IncompatibleFormComponent.new)

    # Bad selector should be present, at least until fixed upstream or included by default
    assert_selector("form > div > input")
  end
end
