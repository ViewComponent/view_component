# frozen_string_literal: true

require "active_support/notifications"

module ViewComponent # :nodoc:
  module Instrumentation
    def self.included(mod)
      mod.prepend(self) unless ancestors.include?(ViewComponent::Instrumentation)
    end

    def render_in(view_context, &block)
      ActiveSupport::Notifications.instrument(
        notification_name,
        {
          name: self.class.name,
          identifier: self.class.identifier
        }
      ) do
        super
      end
    end

    def helpers
      super unless ViewComponent::Base.config.instrumentation_helpers
      ActiveSupport::Notifications.instrument(
        "#{notification_name}.helpers",
        {
          name: self.class.name,
          identifier: self.class.identifier
        }
      ) do
        super
      end
    end

    private

    def notification_name
      return "!render.view_component" if ViewComponent::Base.config.use_deprecated_instrumentation_name

      "render.view_component"
    end
  end
end
