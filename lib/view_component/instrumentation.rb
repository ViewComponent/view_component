# frozen_string_literal: true

require "active_support/notifications"

module ViewComponent # :nodoc:
  module Instrumentation
    def self.included(mod)
      mod.prepend(self) unless self <= ViewComponent::Instrumentation
    end

    def render_in(view_context, &block)
      ActiveSupport::Notifications.instrument(
        "render.view_component",
        {
          name: self.class.name,
          identifier: self.class.identifier
        }
      ) do
        super
      end
    end
  end
end
