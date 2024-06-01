# frozen_string_literal: true

class SlotNameOverrideComponent < ViewComponent::Base
  renders_one :title

  def initialize(classes: "")
    @classes = classes
  end
end
