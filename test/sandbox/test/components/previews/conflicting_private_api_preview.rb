# frozen_string_literal: true

class ConflictingPrivateApiPreview < ViewComponent::Preview
  def default
    render(MyComponent.new)
  end
end
