# frozen_string_literal: true

class NestedCollectionWrapperComponent < ViewComponent::Base
  def initialize(items:)
    @items = items
  end
end
