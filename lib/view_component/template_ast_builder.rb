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
      # Compiling a template to Ruby couples us to the ActionView::Template
      # constructor and the handler-call convention, both of which have changed
      # across Rails versions. Degrade gracefully (return nil so the caller can fall
      # back), but surface the failure through instrumentation so an upgrade break is
      # observable instead of silently producing empty dependencies, which would
      # leave stale caches. The per-handler tests act as the loud CI canary for this
      # path across the supported Rails matrix.
      ActiveSupport::Notifications.instrument(
        "template_ast_build_failed.view_component",
        handler: handler_name, identifier: identifier, error: error
      )
      nil
    end
  end
end
