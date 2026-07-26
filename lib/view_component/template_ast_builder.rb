# frozen_string_literal: true

require "action_view"

module ViewComponent
  class TemplateAstBuilder
    def self.build(template_string, handler_name, identifier: nil)
      handler = ActionView::Template.handler_for_extension(handler_name)
      return nil unless handler

      identifier ||= "inline.#{handler_name}"
      template = ActionView::Template.new(
        template_string,
        identifier,
        handler,
        locals: [],
        virtual_path: identifier
      )

      handler.call(template, template_string)
    rescue => error
      # Instrument rather than silently returning nil: a swallowed compile failure
      # produces empty dependencies and stale caches. Per-handler tests guard this.
      ActiveSupport::Notifications.instrument(
        "template_ast_build_failed.view_component",
        handler: handler_name, identifier: identifier, error: error
      )
      nil
    end
  end
end
