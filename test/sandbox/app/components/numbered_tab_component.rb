# frozen_string_literal: true

class NumberedTabComponent < ViewComponent::Base
  def initialize(title:, slots_counter:)
    @tab_number = slots_counter
    @title = title
  end
end
