# frozen_string_literal: true

require "test_helper"

class WithoutPreviewComponentTest < ViewComponent::TestCase
  def test_render_preview
    error = assert_raises NameError do
      render_preview(:default)
    end

    assert_equal(
      error.message.split(".")[0],
      "`render_preview` expected to find WithoutPreviewComponentPreview, but it does not exist"
    )
  end
end
