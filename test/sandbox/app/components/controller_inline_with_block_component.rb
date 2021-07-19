# frozen_string_literal: true

class ControllerInlineWithBlockComponent < ViewComponent::Base
  renders_one :slot, ->(name:) { tag.div name }

  def initialize(message:)
    @message = message
  end
end
