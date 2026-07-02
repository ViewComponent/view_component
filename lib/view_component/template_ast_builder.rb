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
    rescue
      nil
    end
  end
end
