# frozen_string_literal: true

class CacheDigestorLayoutParentComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache do
    [foo]
  end

  attr_reader :foo

  def initialize(foo:)
    @foo = foo
  end
end
