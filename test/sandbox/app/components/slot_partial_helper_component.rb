# frozen_string_literal: true

class SlotPartialHelperComponent < ViewComponent::Base
  renders_one :header, PartialHelperComponent

  def call
    content_tag :h1 do
      safe_join([
        helpers.expensive_message,
        header.to_s
      ])
    end
  end
end
