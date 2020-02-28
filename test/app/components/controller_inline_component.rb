# frozen_string_literal: true

class ControllerInlineComponent < ActionView::Component::Base
  def initialize(message:)
    @message = message
  end
end
