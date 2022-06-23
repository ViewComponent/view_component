# frozen_string_literal: true

class DelegatedSlotsChildComponent < ViewComponent::Base
  include ViewComponent::DelegatedSlots

  delegate_renders_one :header, to: :@parent do |*args, **kwargs, &set_slot|
    set_slot.call(*args, **{ color: "red", **kwargs })
  end

  delegate_renders_many :items, to: :@parent do |*args, **kwargs, &set_slot|
    set_slot.call(*args, **{ color: "green", **kwargs })
  end

  def initialize
    @parent = DelegatedSlotsParentComponent.new
  end
end
