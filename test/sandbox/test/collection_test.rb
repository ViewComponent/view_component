# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class CollectionTest < TestCase
    def setup
      products = [OpenStruct.new(name: "Radio clock"), OpenStruct.new(name: "Mints")]
      @collection = ProductComponent.with_collection(products, notice: "secondhand")
    end

    def test_collection_has_a_size
      assert_equal 2, @collection.size
      assert_equal 2, @collection.count
    end

    def test_is_a_collection_of_view_components
      assert_equal [ProductComponent], @collection.map(&:class).uniq
    end
  end
end
