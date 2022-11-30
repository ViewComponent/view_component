# frozen_string_literal: true

class SlotsComponent < ViewComponent::Base
  include ViewComponent::Slotable

  with_slot :title, class_name: "Title"
  with_slot :subtitle
  with_slot :footer, class_name: "Footer"
  with_slot :tab, collection: true
  with_slot :item, collection: true, class_name: "Item"

  class Title < ViewComponent::Slot
  end

  class Item < ViewComponent::Slot
    def initialize(highlighted: false)
      @highlighted = highlighted
    end

    def class_names
      @highlighted ? "highlighted" : "normal"
    end
  end

  class Footer < ViewComponent::Slot
    attr_reader :class_names

    def initialize(class_names: "")
      @class_names = class_names
    end
  end

  def initialize(class_names: "")
    @class_names = class_names
  end
end
