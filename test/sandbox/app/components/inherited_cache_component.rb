# frozen_string_literal: true

class InheritedCacheComponent < CacheComponent
  def initialize(foo:, bar:)
    super
  end
end
