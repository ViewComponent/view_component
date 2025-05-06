module CachingRegistry # :nodoc:
    extend self

    def caching?
      ActiveSupport::IsolatedExecutionState[:action_view_caching] ||= false
    end

    def track_caching
      caching_was = ActiveSupport::IsolatedExecutionState[:action_view_caching]
      ActiveSupport::IsolatedExecutionState[:action_view_caching] = true

      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:action_view_caching] = caching_was
    end
end
