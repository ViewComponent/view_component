# frozen_string_literal: true

class CacheDigestorParentComponent < ViewComponent::Base
  include ViewComponent::Cacheable

  cache_on :foo

  attr_reader :foo

  def initialize(foo:)
    @foo = foo
  end
end
