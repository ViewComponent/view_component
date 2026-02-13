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

    def report_rows
      @report_rows ||= Array.new(36) do |index|
        sequence = index + 1
        amount = ((sequence * 13.75) + (sequence % 4) * 2.125)

        {
          label: "#{name} item #{sequence}",
          amount: amount,
          events: (sequence * 7) % 11 + 1,
          score: ((sequence * 41) % 100) + 1,
          slug: "#{name.downcase.tr(" ", "-")}-#{sequence}"
        }
      end
    end

    def total_score
      report_rows.sum { _1[:score] }
    end
  end
end
