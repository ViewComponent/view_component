# frozen_string_literal: true

require "test_helper"
require "pry"

class ExampleComponentTest < ViewComponent::TestCase
  def test_render_component
    binding.pry

    render_inline(Shared::ExampleComponent.new(title: "my title")) { "Hello, World!" }

    assert_selector("span[title='my title']", text: "Hello, World!")
    # or, to just assert against the text:
    assert_text("Hello, World!")
  end
end