# frozen_string_literal: true

# Renders a component that static analysis can't see and that hasn't opted into
# caching, declared with the `# Template Dependency:` escape hatch.
class CacheablePlainDependencyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: ErbComponent

  def initialize(component: ErbComponent)
    @component = component
  end

  def call
    render @component.new(message: "plain")
  end
end
