# frozen_string_literal: true

class ProductComponent < ViewComponent::Base
  def initialize(product:, notice:, count: nil, product_counter: nil)
    @product = product
    @notice  = notice
    @count   = count
    @counter = product_counter
  end
end
