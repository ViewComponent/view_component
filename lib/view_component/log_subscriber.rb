# frozen_string_literal: true

module ViewComponent
  class LogSubscriber < ActiveSupport::LogSubscriber
    def render_template(event)
      debug do
        message = +"  Rendered #{event.payload[:component_name]}"
        message << " (Duration: #{event.duration.round(1)}ms | Allocations: #{event.allocations})"
      end
    end

    def render_collection(event)
      debug do
        message = +"  Rendered collection of #{event.payload[:component_name]}"
        message << " [#{event.payload[:count]} times] (Duration: #{event.duration.round(1)}ms | Allocations: #{event.allocations})"
        message
      end
    end

    def logger
      ActionView::Base.logger
    end
  end
end

ViewComponent::LogSubscriber.attach_to :view_component
