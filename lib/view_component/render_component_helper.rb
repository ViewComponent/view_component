# frozen_string_literal: true

module ViewComponent
  module RenderComponentHelper # :nodoc:
    def render_component(component, &block)
      component.render_in(self, &block)
    end
  end
end
