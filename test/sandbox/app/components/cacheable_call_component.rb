# frozen_string_literal: true

# Renders a child component from a `call` method rather than a template.
class CacheableCallComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  def call
    render CacheableChildComponent.new
  end
end
