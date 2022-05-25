# frozen_string_literal: true

require "test_helper"

class MyComponentTest < ViewComponent::TestCase
  include ViewComponent::RenderPreviewHelper

  def test_render_preview
    Rails.autoloaders.main.push_dir(Rails.root.join("test/components/previews"))
    render_preview(:default)

    assert_selector("div", text: "hello,world!")
  end
end
