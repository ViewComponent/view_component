# frozen_string_literal: true

module Performance
  class JbuilderCachedBenchmarkComponent < HandlerBenchmarkComponent
    include ViewComponent::ExperimentallyCacheable

    cache do
      [name]
    end
  end
end
