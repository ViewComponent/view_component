# frozen_string_literal: true

class CacheCycleAComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [:a] }
end
