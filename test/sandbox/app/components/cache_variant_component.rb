# frozen_string_literal: true

class CacheVariantComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [:v] }
end
