# frozen_string_literal: true

class NumberedTabComponent < ViewComponent::Base
  def initialize(title:, numbered_tab_counter:, numbered_tab_iteration:)
    @tab_number = numbered_tab_counter
    @tab_iteration = numbered_tab_iteration
    @title = title
  end
end
