# frozen_string_literal: true

class CacheLocaleComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache do
    [:cache_locale_component]
  end
end
