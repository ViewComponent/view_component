# frozen_string_literal: true

# Two `cache_on` values where either may be nil, so positional collisions are
# visible in the key.
class PositionalCacheKeyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :first, :second

  def initialize(first:, second:)
    @first = first
    @second = second
  end

  def call
    "#{first}-#{second}".html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  attr_reader :first, :second
end
