# frozen_string_literal: true

module Performance
  class CacheableBenchmarkComponent < ViewComponent::Base
    include ViewComponent::ExperimentallyCacheable

    cache_if :cache_worthy?
    cache_on :name

    attr_reader :name

    def initialize(name:)
      @name = name
    end

    def cache_worthy?
      !name.match?(/\d+\z/)
    end
  end
end
