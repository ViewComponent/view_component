# frozen_string_literal: true

class RendersNonComponent < ViewComponent::Base
  class NotAComponent
    attr_reader :render_in_view_context, :original_view_context

    def render_in(view_context)
      @render_in_view_context = view_context
      "<span>I'm not a component</span>".html_safe
    end

    def set_original_view_context(view_context)
      @original_view_context = view_context
    end
  end

  def initialize(not_a_component:)
    @not_a_component = not_a_component
  end
end
