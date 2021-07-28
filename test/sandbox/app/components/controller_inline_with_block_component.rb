# frozen_string_literal: true

class ControllerInlineWithBlockComponent < ViewComponent::Base
  renders_one :slot, ->(name:) { tag.div name, id: "slot" }

  def initialize(message:)
    @message = message
  end
end
