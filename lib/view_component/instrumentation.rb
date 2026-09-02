# frozen_string_literal: true

require "active_support/notifications"

module ViewComponent # :nodoc:
  module Instrumentation
    def self.included(mod)
      mod.prepend(self) unless self <= ViewComponent::Instrumentation
    end

    class << self
      attr_accessor :enabled
    end

    def render_in(view_context, &block)
      return super unless Instrumentation.enabled

      payload = {
        name: self.class.name,
        identifier: self.class.identifier,
        view_identifier: nil
      }

      ActiveSupport::Notifications.instrument(
        "render.view_component",
        payload
      ) do
        result = super
        payload[:view_identifier] = @__vc_instrumentation_view_identifier
        result
      end
    ensure
      @__vc_instrumentation_view_identifier = nil
    end

    def around_render
      result = super
      @__vc_instrumentation_view_identifier = current_template&.path
      result
    end
  end
end
