# frozen_string_literal: true

module Performance
  class ErbCachedBenchmarkComponent < HandlerBenchmarkComponent
    include ViewComponent::ExperimentallyCacheable

    cache do
      [name]
    end
  end
end
