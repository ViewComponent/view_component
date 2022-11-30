# frozen_string_literal: true

module ViewComponent
  module RenderingComponentHelper # :nodoc:
    def render_component(component)
      self.response_body = component.render_in(view_context)
    end
  end
end
