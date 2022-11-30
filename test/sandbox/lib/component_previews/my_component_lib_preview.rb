# frozen_string_literal: true

class MyComponentLibPreview < ViewComponent::Preview
  layout false

  def default
    render(MyComponent.new)
  end
end
