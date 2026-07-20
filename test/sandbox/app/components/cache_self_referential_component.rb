# frozen_string_literal: true

class CacheSelfReferentialComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [:self] }
end
