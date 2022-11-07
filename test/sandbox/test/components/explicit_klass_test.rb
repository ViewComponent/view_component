# frozen_string_literal: true

require "test_helper"

class ExplicitKlassTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.load_previews
  end

  def test_render_preview_with_klass
    render_preview(:default, klass: MyComponentPreview)

    assert_selector("div", text: "hello,world!")
  end
end
