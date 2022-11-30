# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class CollectionTest < TestCase
    class ProductComponent < ViewComponent::Base
      attr_accessor :product

      def initialize(**attributes)
        self.product = attributes[:product]
      end

      def call
        "<div data-name='#{product.name}'><h1>#{product.name}</h1></div>"
      end
    end

    def setup
      @products = [OpenStruct.new(name: "Radio clock"), OpenStruct.new(name: "Mints")]
      @collection = ProductComponent.with_collection(@products, notice: "secondhand")
    end

    def test_collection_has_a_size
      assert_equal 2, @collection.size
      assert_equal 2, @collection.count
    end

    def test_is_a_collection_of_view_components
      assert_equal [ProductComponent], @collection.map(&:class).uniq
    end

    def test_supports_components_with_keyword_args
      render_inline(ProductComponent.with_collection(@products))
      assert_selector("*[data-name='#{@products.first.name}']", text: @products.first.name)
      assert_selector("*[data-name='#{@products.last.name}']", text: @products.last.name)
    end
  end
end
