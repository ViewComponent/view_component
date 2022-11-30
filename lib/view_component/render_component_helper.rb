# frozen_string_literal: true

module ViewComponent
  module RenderComponentHelper # :nodoc:
    def render_component(component, &block)
      component.set_original_view_context(__vc_original_view_context) if is_a?(ViewComponent::Base)
      component.render_in(self, &block)
    end
  end
end
