# frozen_string_literal: true

class ProductComponent < ViewComponent::Base
  def initialize(product:, notice:)
    @product = product
    @notice = notice
  end
end
