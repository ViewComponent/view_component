# frozen_string_literal: true

class ErbComponentPreview < ActionView::Component::Preview
  def default
    render(ErbComponent, message: "Bye!") { "Hello World!" }
  end

  def with_args(message: "Bye!", content: "Hello World!")
    render(ErbComponent, message: message) { content }
  end
end
