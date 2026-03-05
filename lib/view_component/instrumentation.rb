# frozen_string_literal: true

require "active_support/notifications"

module ViewComponent # :nodoc:
  module Instrumentation
    # @param mod [Module] the module being included into
    def self.included(mod)
      mod.prepend(self) unless self <= ViewComponent::Instrumentation
    end

    # @param view_context [ActionView::Base] the view context
    # @param block [Proc] optional block
    def render_in(view_context, &block)
      return super if !Rails.application.config.view_component.instrumentation_enabled.present?

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
