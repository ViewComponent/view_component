# frozen_string_literal: true

class NoCacheComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  attr_reader :foo, :bar

  def initialize(foo:, bar:)
    @foo = foo
    @bar = bar
  end
end
