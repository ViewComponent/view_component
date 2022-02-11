# frozen_string_literal: true

class ControllerInlineWithBlockComponent < ViewComponent::Base
  renders_one :slot, ->(name:) do
    if Rails.version.to_f >= 5.2
      tag.div name, id: "slot"
    else
      content_tag(:div, name, id: "slot")
    end
  end

  def initialize(message:)
    @message = message
  end
end
