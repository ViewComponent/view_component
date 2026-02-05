# frozen_string_literal: true

class SlotArgsComponent < ViewComponent::Base
  renders_one :greeting
  renders_many :items
  renders_one :kwargs_slot
  renders_one :mixed_slot
end
