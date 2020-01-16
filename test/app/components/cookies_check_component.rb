# frozen_string_literal: true

class CookiesCheckComponent < ActionView::Component::Base
  def initialize(*); end

  def render?
    !controller.send(:cookies)[:shown]
  end
end
