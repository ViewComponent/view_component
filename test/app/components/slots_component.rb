# frozen_string_literal: true

class SlotsComponent < ViewComponent::Base
  with_slot :title
  with_slot :subtitle
  with_slot :footer, -> { Footer }
  with_slot :tab, collection: true
  with_slot :item, -> { Item }, collection: true

  def initialize(class_names: "")
    @class_names = class_names
  end

  class Item < ViewComponent::Slot
    def initialize(highlighted: false)
      @highlighted = highlighted
    end

    def class_names
      @highlighted ? "highlighted" : "normal"
    end
  end
  private_constant :Item

  class Footer < ViewComponent::Slot
    attr_reader :class_names

    def initialize(class_names: "")
      @class_names = class_names
    end
  end
  private_constant :Footer
end
