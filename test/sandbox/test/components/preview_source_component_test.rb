# frozen_string_literal: true

require "test_helper"

class PreviewSourceComponentTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.load_previews
  end

  def test_render_preview
    Rails.application.config.view_component.stub(:show_previews_source, true) do
      render_preview(:default)

      assert_text "Hello world"
    end
  end
end
