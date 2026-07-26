# frozen_string_literal: true

class CacheHtmlSafetyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [:h] }
end
