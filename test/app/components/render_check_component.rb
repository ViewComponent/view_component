# frozen_string_literal: true

class RenderCheckComponent < ActionView::Component::Base
  before_render do
    self.rendered_output = "" unless render?
  end

  def initialize(*); end

  def render?
    !view_context.cookies[:shown]
  end
end
