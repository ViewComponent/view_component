# frozen_string_literal: true

class CollectionCompileComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:, item_counter: nil)
    @item = item
  end
end
