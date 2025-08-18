# frozen_string_literal: true

require "test_helper"

class RelativeTranslationPartialComponentTest < ViewComponent::TestCase
  def test_relative_translation_in_partial_block
    render_inline(RelativeTranslationPartialParentComponent.new)

    assert_text "Test Component Title"
  end
end
