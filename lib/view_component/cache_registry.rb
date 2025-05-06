  
module ViewComponent
  module CachingRegistry # :nodoc:
    extend self

    def caching?
      ActiveSupport::IsolatedExecutionState[:view_component_caching] ||= false
    end

    def track_caching
      caching_was = ActiveSupport::IsolatedExecutionState[:view_component_caching]
      ActiveSupport::IsolatedExecutionState[:action_view_caching] = true

      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:view_component_caching] = caching_was
    end
  end
end
