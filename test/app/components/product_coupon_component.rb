# frozen_string_literal: true

class ProductCouponComponent < ViewComponent::Base
  def initialize(item:)
    @item = item
  end
end
