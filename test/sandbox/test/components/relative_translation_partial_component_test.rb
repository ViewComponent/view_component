# frozen_string_literal: true

require "test_helper"

class RelativeTranslationPartialComponentTest < ViewComponent::TestCase
  def test_relative_translation_in_partial_block
    render_inline(RelativeTranslationPartialParentComponent.new)

    # This should pass if Rails resolves the translation key relative to the caller's path,
    # but currently fails because it resolves relative to the partial's path.
    assert_text "Test Component Title"

    # This assertion documents the current (incorrect) behavior.
    assert_no_text "Partial Title"
  end
end
