# frozen_string_literal: true

class ProductReaderOopsComponent < ViewComponent::Base
  attr_reader :product,
              :notice,

  def initialize(product_reader_oops:, notice:)
    @product = product_reader_oops
    @notice  = notice
  end
end
