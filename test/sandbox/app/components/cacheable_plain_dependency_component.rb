# frozen_string_literal: true

class CacheablePlainDependencyComponent < ViewComponent::Base
  # Template Dependency: ErbComponent

  def initialize(component: ErbComponent)
    @component = component
  end

  def call
    render @component.new(message: "plain")
  end
end
