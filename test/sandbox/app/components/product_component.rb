# frozen_string_literal: true

class ProductComponent < ViewComponent::Base
  def initialize(product:, notice:, product_counter: nil, product_iteration: nil)
    @product = product
    @notice = notice
    @counter = product_counter
    @iteration = product_iteration
  end
end
