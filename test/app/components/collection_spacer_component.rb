# frozen_string_literal: true

class CollectionSpacerComponent < ViewComponent::Base
  def initialize(item:, index:)
    @item = item
    @index = index
  end
end
