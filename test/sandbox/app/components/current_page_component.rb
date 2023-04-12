# frozen_string_literal: true

class CurrentPageComponent < ViewComponent::Base
  def text
    if current_page?("/slots")
      "Inside /slots"
    else
      "Outside /slots"
    end
  end
end
