# frozen_string_literal: true

class DeprecatedSlotsSetterComponent < ViewComponent::Base
  warn_on_deprecated_slot_setter

  renders_one :header
  renders_many :items

  def call
    header
    items
  end
end
