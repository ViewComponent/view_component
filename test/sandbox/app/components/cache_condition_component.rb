# frozen_string_literal: true

class CacheConditionComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_if :cache_enabled?
  cache_on :foo

  attr_reader :foo

  def initialize(foo:)
    @foo = foo
  end

  def cache_enabled?
    false
  end
end
