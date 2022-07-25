# frozen_string_literal: true

class SlotsV3DeprecationComponent < ViewComponent::Base
  raise_on_deprecated_slot_setter

  renders_one :label
  renders_many :items

  def call
    content
  end
end
