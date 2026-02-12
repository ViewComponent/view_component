# frozen_string_literal: true

module Performance
  class CacheableBenchmarkComponent < ViewComponent::Base
    include ViewComponent::ExperimentallyCacheable

    cache_on :name

    attr_reader :name

    def initialize(name:)
      @name = name
    end
  end
end
