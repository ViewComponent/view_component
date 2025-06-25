# frozen_string_literal: true

module TestEngine
  class ExampleComponentPreview < ViewComponent::Preview
    def default
      render(ExampleComponent.new)
    end
  end
end
