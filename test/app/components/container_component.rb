# frozen_string_literal: true

class ContainerComponent < ViewComponent::Base
  def initialize(nested_component:)
    @nested_component = nested_component
  end

  def call
    render @nested_component
  end
end
