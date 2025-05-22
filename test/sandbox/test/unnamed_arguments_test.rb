require "test_helper"

module ViewComponent
  class UnnamedArgumentsTest < TestCase
    class DynamicComponentBase < ViewComponent::Base
      def setup_component(**attributes)
        # This method is somewhat contrived, it's intended to mimic features available in the dry-initializer gem.
        model_name = self.class.name.demodulize.delete_suffix('Component').underscore.to_sym
        instance_variable_set(:"@#{model_name}", attributes[model_name])
        define_singleton_method(model_name) { instance_variable_get(:"@#{model_name}") }
      end
    end

    class OrderComponent < DynamicComponentBase
      def initialize(**)
        setup_component(**)
      end
      def call
        "<div data-name='#{order.object_id}'><h1>#{order.object_id}</h1></div>".html_safe
      end
    end

    class CustomerComponent < DynamicComponentBase
      def initialize(...)
        setup_component(...)
      end
      def call
        "<div data-name='#{customer.name}'><h1>#{customer.name}</h1></div>".html_safe
      end
    end

    class Nameable
      attr_reader :name

      def initialize(name:)
        @name = name
      end
    end

    def setup
      @customers = [Nameable.new(name: "Taylor"), Nameable.new(name: "Rowan")]
      @orders = [Nameable.new(name: "O-2024-0004"), Nameable.new(name: "B-2024-0714")]
    end

    def test_supports_components_with_argument_forwarding
      render_inline(CustomerComponent.with_collection(@customers))
      assert_selector("*[data-name='#{@customers.first.name}']", text: @customers.first.name)
      assert_selector("*[data-name='#{@customers.last.name}']", text: @customers.last.name)
    end

    def test_supports_components_with_unnamed_splatted_arguments
      render_inline(OrderComponent.with_collection(@orders))
      assert_selector("*[data-name='#{@orders.first.object_id}']", text: @orders.first.object_id)
      assert_selector("*[data-name='#{@orders.last.object_id}']", text: @orders.last.object_id)
    end
  end
end