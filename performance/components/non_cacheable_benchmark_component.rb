# frozen_string_literal: true

module Performance
  class NonCacheableBenchmarkComponent < ViewComponent::Base
    attr_reader :name

    def initialize(name:)
      @name = name
    end
  end
end
