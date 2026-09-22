# frozen_string_literal: true

# Ancestor of CacheBlockComponent, so changes here must invalidate the fragment
# that component's template caches.
class CacheBlockBaseComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable
end
