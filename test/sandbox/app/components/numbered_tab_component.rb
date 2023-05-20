# frozen_string_literal: true

class NumberedTabComponent < ViewComponent::Base
  def initialize(title:, numbered_tab_counter:)
    @tab_number = numbered_tab_counter
    @title = title
  end
end
