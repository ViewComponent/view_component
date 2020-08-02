# frozen_string_literal: true

module ViewComponent
  class LogSubscriber < ActiveSupport::LogSubscriber
    def render_template(event)
      info do
        message = +"  Rendered #{event.payload[:component_name]}"
        message << " (Duration: #{event.duration.round(1)}ms | Allocations: #{event.allocations})"
      end
    end

    def render_collection(event)
      debug do
        message = +"  Rendered collection of #{event.payload[:component_name]}"
        message << " #{render_count(event.payload)} (Duration: #{event.duration.round(1)}ms | Allocations: #{event.allocations})"
        message
      end
    end

    def logger
      ActionView::Base.logger
    end

    private

    def render_count(payload) # :doc:
      if payload[:cache_hits]
        "[#{payload[:cache_hits]} / #{payload[:count]} cache hits]"
      else
        "[#{payload[:count]} times]"
      end
    end
  end
end

ViewComponent::LogSubscriber.attach_to :view_component
