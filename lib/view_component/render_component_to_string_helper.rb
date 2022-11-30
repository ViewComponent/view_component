# frozen_string_literal: true

module ViewComponent
  module RenderComponentToStringHelper # :nodoc:
    def render_component_to_string(component)
      component.render_in(view_context)
    end
  end
end
