# frozen_string_literal: true

class CacheDigestorPartialParentComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :foo

  attr_reader :foo

  def initialize(foo:)
    @foo = foo
  end
end
