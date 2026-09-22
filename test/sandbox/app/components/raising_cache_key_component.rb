# frozen_string_literal: true

class RaisingCacheKeyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :identity

  def call
    "raising cache key"
  end

  private

  def identity
    raise "boom"
  end
end
