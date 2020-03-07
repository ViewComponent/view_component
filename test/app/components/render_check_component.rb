# frozen_string_literal: true

class RenderCheckComponent < ViewComponent::Base
  def render?
    !view_context.cookies[:shown]
  end
end
