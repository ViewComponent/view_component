# frozen_string_literal: true

class SlotsComponent < ViewComponent::Base
  with_slot(:title)
  with_slot(:subtitle)
  with_slot(:footer)
  with_slot(:tab, collection: true)
  with_slot(:item, class_name: "SlotsComponent::Item", collection: true)

  def initialize(class_names: "")
    @class_names = class_names
  end

  private

  class Title < ViewComponent::Slot
    def initialize
    end
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
end
