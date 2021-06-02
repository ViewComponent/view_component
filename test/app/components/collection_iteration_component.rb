# frozen_string_literal: true

class CollectionIterationComponent < ViewComponent::Base
  with_collection_parameter :item

  def initialize(item:, item_iteration:)
    @item = item
    @iteration = item_iteration
    @counter = @iteration.index + 1
  end
end
