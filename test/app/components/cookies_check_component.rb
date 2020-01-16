# frozen_string_literal: true

class CookiesCheckComponent < ActionView::Component::Base
  def initialize(*); end

  def render?
    !view_context.cookies[:shown]
  end
end
