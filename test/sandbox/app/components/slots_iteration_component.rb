# frozen_string_literal: true

class SlotsIterationComponent < ViewComponent::Base
  renders_many :numbered_tabs, NumberedTabComponent

  def initialize(classes: "")
    @classes = classes
  end
end
