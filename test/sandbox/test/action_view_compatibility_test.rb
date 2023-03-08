# frozen_string_literal: true

require "test_helper"

class ViewComponent::ActionViewCompatibilityTest < ViewComponent::TestCase
  def test_renders_form_for_labels_with_block_correctly
    skip unless ENV["CAPTURE_PATCH_ENABLED"] == "true"
    render_inline(FormForComponent.new)

    assert_selector("form > div > label > input")
    refute_selector("form > div > input")
  end

  def test_renders_form_with_labels_with_block_correctly
    skip unless ENV["CAPTURE_PATCH_ENABLED"] == "true"
    render_inline(FormWithComponent.new)

    assert_selector("form > div > label > input")
    refute_selector("form > div > input")
  end

  def test_form_without_compatibility_does_not_raise
    skip unless ENV["CAPTURE_PATCH_ENABLED"] == "true"
    render_inline(IncompatibleFormComponent.new)

    # Bad selector should be present, at least until fixed upstream or included by default
    refute_selector("form > div > input")
  end

  def test_form_with_partial_render_works
    skip unless ENV["CAPTURE_PATCH_ENABLED"] == "true"
    render_inline(FormPartialComponent.new)

    # Bad selector should be present, at least until fixed upstream or included by default
    refute_selector("form > div > input")
  end

  def test_helper_with_content_tag
    skip unless ENV["CAPTURE_PATCH_ENABLED"] == "true"
    render_inline(ContentTagComponent.new)
    assert_selector("div > p")
  end
end
