# frozen_string_literal: true

# Same as CacheableDynamicComponent, but naming the component class directly
# rather than its internal digest path.
class CacheableDynamicConstantComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: CacheableChildComponent

  def initialize(component: CacheableChildComponent)
    @component = component
  end

  def call
    render @component.new
  end
end
