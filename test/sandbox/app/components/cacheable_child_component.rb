# frozen_string_literal: true

class CacheableChildComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable
end
