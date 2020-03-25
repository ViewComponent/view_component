# frozen_string_literal: true

class ProductItemComponent < ViewComponent::Base
  def initialize(product_item:, extra:)
    @product_item = product_item
    @extra = extra
  end
end
