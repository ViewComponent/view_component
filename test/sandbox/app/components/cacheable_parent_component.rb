# frozen_string_literal: true

# Renders a child component, so changes to the child must invalidate the parent.
class CacheableParentComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable
end
