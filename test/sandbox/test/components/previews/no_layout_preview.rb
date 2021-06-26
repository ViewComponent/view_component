# frozen_string_literal: true

class NoLayoutPreview < ViewComponent::Preview
  layout false

  def default
    render(MyComponent.new)
  end
end
