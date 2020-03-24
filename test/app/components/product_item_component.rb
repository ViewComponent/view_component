# frozen_string_literal: true

class ProductItemComponent < ViewComponent::Base
  def initialize(item:, extra:)
    @product = item
    @extra = extra
  end
end
