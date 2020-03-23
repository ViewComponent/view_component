# frozen_string_literal: true

class ProductComponent < ViewComponent::Base
  def initialize(product:, extra:)
    @product = product
    @extra = extra
  end
end