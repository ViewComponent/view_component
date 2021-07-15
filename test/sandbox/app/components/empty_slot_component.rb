# frozen_string_literal: true

class EmptySlotComponent < ViewComponent::Base
  include ViewComponent::Slotable

  with_slot :title

  def call
    title.content
  end
end
