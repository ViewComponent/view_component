# frozen_string_literal: true

class CacheableUnreadableDigestSourceComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  def call
    "unreadable digest source"
  end
end
