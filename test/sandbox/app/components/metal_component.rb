# frozen_string_literal: true

class MetalComponent < ViewComponent::Metal
  def call
    button type: :button do
      p "Hello"
      span do
        strong { " World" }
      end
    end
  end
end
