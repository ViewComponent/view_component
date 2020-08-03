# frozen_string_literal: true

module ViewComponent
  class LogSubscriber < ActiveSupport::LogSubscriber
    def render_template(event)
      debug do
        message = +"  Rendered #{event.payload[:component_name]}"
        message << " (#{duration_and_allocations(event)})"
      end
    end

    def render_collection(event)
      debug do
        message = +"  Rendered collection of #{event.payload[:component_name]}"
        message << " [#{event.payload[:count]} times] (#{duration_and_allocations(event)})"
        message
      end
    end

    def logger
      ActionView::Base.logger
    end

    private

    def duration_and_allocations(event)
      message = +"Duration: #{event.duration.round(1)}ms"
      message << " | Allocations: #{event.allocations}" if event.respond_to?(:allocations)
      message
    end
  end
end

ViewComponent::LogSubscriber.attach_to :view_component
