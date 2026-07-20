# frozen_string_literal: true

class CacheIfPrivateComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_if :cacheable?
  cache do
    [foo]
  end

  attr_reader :foo

  def initialize(foo:)
    @foo = foo
  end

  private

  def cacheable?
    true
  end
end
