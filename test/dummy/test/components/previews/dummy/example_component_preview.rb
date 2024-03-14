# frozen_string_literal: true

module Dummy
  class ExampleComponentPreview < ViewComponent::Preview
    def default
      render(ExampleComponent.new)
    end
  end
end
