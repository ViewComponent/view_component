# frozen_string_literal: true

class BadSlotComponent < ViewComponent::Base
  include ViewComponent::Slotable

  with_slot :title, class_name: "Title"

  # slots must inherit from ViewComponent::Slot!
  class Title; end
end
