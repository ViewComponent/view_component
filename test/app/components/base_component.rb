# frozen_string_literal: true

class BaseComponent < ActionView::Component::Base
  def initialize(message:)
    @message = message
  end
end
