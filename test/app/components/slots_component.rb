# frozen_string_literal: true

class SlotsComponent < ViewComponent::Base
  with_slots :subtitle
  with_collection_slots :tab

  class Title < ViewComponent::Slot
    def initialize
    end
  end

  class Item < ViewComponent::CollectionSlot
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
