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

    def test_collection_escapes_html_unsafe_around_render_output
      capture_warnings do
        render_inline(UnsafeAroundRenderComponent.with_collection([1, 2]))
      end

      refute_includes @rendered_content, "<script>"
      assert_includes @rendered_content, "&lt;script&gt;alert(1)&lt;/script&gt;"
      assert_predicate @rendered_content, :html_safe?
    end

    class ExplicitCountersComponent < ViewComponent::Base
      with_collection_parameter :item, counter: true, iteration: true

      def initialize(**)
        assign(**)
      end

      def call
        "<p>#{@item.name} #{@counter.inspect} #{@iteration&.last?.inspect}</p>".html_safe
      end

      private

      def assign(item:, **options)
        @item = item
        @counter = options[:item_counter]
        @iteration = options[:item_iteration]
      end
    end

    class InheritedExplicitCountersComponent < ExplicitCountersComponent
    end

    class DisabledCountersComponent < ExplicitCountersComponent
      with_collection_parameter counter: false, iteration: false

      def initialize(item:, item_counter: nil, item_iteration: nil)
        @item = item
        @counter = item_counter
        @iteration = item_iteration
      end
    end

    def test_with_collection_parameter_passes_counter_and_iteration
      render_inline(ExplicitCountersComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 0 false")
      assert_selector("p", text: "Mints 1 true")
    end

    def test_with_collection_parameter_counter_and_iteration_are_inherited
      render_inline(InheritedExplicitCountersComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 0 false")
      assert_selector("p", text: "Mints 1 true")
    end

    def test_with_collection_parameter_counter_and_iteration_false_skips_them
      render_inline(DisabledCountersComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock nil nil")
      assert_selector("p", text: "Mints nil nil")
    end
  end
end
