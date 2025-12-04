# frozen_string_literal: true

require "test_helper"

class RelativeTranslationPartialBlockComponentTest < ViewComponent::TestCase
  def test_relative_translation_in_partial_block
    render_inline(RelativeTranslationPartialBlockComponent.new)

    assert_text "Partial Title"
  end
end
