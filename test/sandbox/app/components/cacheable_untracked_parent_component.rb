# frozen_string_literal: true

# Renders a child that never opted in, so changes to the child must still
# invalidate the parent.
class CacheableUntrackedParentComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable
end
