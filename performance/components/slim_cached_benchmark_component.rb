# frozen_string_literal: true

module Performance
  class SlimCachedBenchmarkComponent < HandlerBenchmarkComponent
    include ViewComponent::ExperimentallyCacheable

    cache do
      [name]
    end
  end
end
