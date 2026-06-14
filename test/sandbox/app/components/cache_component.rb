# frozen_string_literal: true

class CacheComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache do
    [foo, bar]
  end

  attr_reader :foo, :bar

  def initialize(foo:, bar:)
    @foo = foo
    @bar = bar
  end
end
