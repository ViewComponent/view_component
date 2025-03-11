# frozen_string_literal: true

require "test_helper"

class ViewComponent::ActionViewCompatibilityTest < ViewComponent::TestCase
  def test_renders_form_for_labels_with_block_correctly
    skip unless Rails.application.config.view_component.capture_compatibility_patch_enabled

    render_inline(FormForComponent.new)

    assert_selector("form > div > label > input")
    refute_selector("form > div > input")
  end

  def test_renders_form_with_labels_with_block_correctly
    skip unless Rails.application.config.view_component.capture_compatibility_patch_enabled

    render_inline(FormWithComponent.new)

    assert_selector("form > div > label > input")
    refute_selector("form > div > input")
  end

  def test_form_without_compatibility_does_not_raise
    skip unless Rails.application.config.view_component.capture_compatibility_patch_enabled
    render_inline(IncompatibleFormComponent.new)

    # Bad selector should be present, at least until fixed upstream or included by default
    refute_selector("form > div > input")
  end

  def test_form_with_partial_render_works
    skip unless Rails.application.config.view_component.capture_compatibility_patch_enabled

    render_inline(FormPartialComponent.new)

    # Bad selector should be present, at least until fixed upstream or included by default
    refute_selector("form > div > input")
  end

  def test_helper_with_content_tag
    skip unless Rails.application.config.view_component.capture_compatibility_patch_enabled

    render_inline(ContentTagComponent.new)
    assert_selector("div > p")
  end

  def test_including_compat_module_twice_does_not_blow_the_stack
    skip unless Rails.application.config.view_component.capture_compatibility_patch_enabled

    ActionView::Base.include(ViewComponent::CaptureCompatibility)
    render_inline(FormForComponent.new)
    assert_selector("form > div > label > input")
    refute_selector("form > div > input")
  end
end
