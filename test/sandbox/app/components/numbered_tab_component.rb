# frozen_string_literal: true

class NumberedTabComponent < ViewComponent::Base
  def initialize(numbered_tab_itteration:, title:)
    @tab_number = numbered_tab_itteration
    @title = title
  end
end
