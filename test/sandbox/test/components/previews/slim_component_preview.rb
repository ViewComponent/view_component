# frozen_string_literal: true

class SlimComponentPreview < ViewComponent::Preview
  def default
    render(SlimComponent.new(message: "Hello"))
  end
end
