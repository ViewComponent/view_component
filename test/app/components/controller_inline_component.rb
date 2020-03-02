# frozen_string_literal: true

class ControllerInlineComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
