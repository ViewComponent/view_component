# frozen_string_literal: true

class CacheDigestorSlimParentComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  attr_reader :foo

  cache do
    [foo]
  end

  def initialize(foo:)
    @foo = foo
  end
end
