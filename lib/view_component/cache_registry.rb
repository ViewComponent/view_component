# frozen_string_literal: true

module ViewComponent
  module CachingRegistry
    extend self

    def caching?
      ActiveSupport::IsolatedExecutionState[:view_component_caching] ||= false
    end

    def track_caching
      caching_was = ActiveSupport::IsolatedExecutionState[:view_component_caching]
      ActiveSupport::IsolatedExecutionState[:view_component_caching] = true

      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:view_component_caching] = caching_was
    end
  end
end
