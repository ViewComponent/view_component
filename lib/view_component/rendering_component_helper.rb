# frozen_string_literal: true

module ViewComponent
  module RenderingComponentHelper # :nodoc:
    def render_component(component, &block)
      self.response_body = component.render_in(self.view_context)
    end
  end
end
