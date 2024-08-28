# frozen_string_literal: true

class RenderCheckComponent < ViewComponent::Base
  def render?
    !view_context.cookies[:hide]
  end

  def call
    "Rendered".html_safe
  end
end
