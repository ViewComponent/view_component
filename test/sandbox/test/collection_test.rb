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
        "<div data-name='#{product.name}'><h1>#{product.name}</h1></div>".html_safe
      end
    end

    class SpacerComponent < ViewComponent::Base
      def call
        "<hr>".html_safe
      end
    end

    # Renders a plain partial, which routes through `ViewComponent::Base#render`
    # and so depends on `__vc_original_view_context` being set.
    class PartialRenderingComponent < ViewComponent::Base
      with_collection_parameter :item

      def initialize(item: nil)
        @item = item
      end

      def call
        render partial: "integration_examples/test_partial"
      end
    end

    def setup
      @products = [Product.new(name: "Radio clock"), Product.new(name: "Mints")]
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

    def test_supports_collection_with_spacer_component
      render_inline(ProductComponent.with_collection(@products, spacer_component: SpacerComponent.new))
      assert_selector("hr", count: 1)
    end

    # A collection rendered from a plain view (rather than from inside another
    # component) never has `set_original_view_context` called on it, so its own
    # `__vc_original_view_context` is nil. That nil must not be forwarded to the
    # child components, or rendering a partial from one raises NoMethodError.
    def test_supports_components_that_render_partials
      render_inline(PartialRenderingComponent.with_collection([1, 2]))

      assert_text("hello,partial world!", count: 2)
    end
  end
end
