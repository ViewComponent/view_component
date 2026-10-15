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

    module ForwardAllArguments
      def initialize(...)
        super
      end
    end

    module ForwardAnonymousSplats
      def initialize(*, **)
        super
      end
    end

    class ForwardedCounterComponent < ViewComponent::Base
      with_collection_parameter :item

      def initialize(item:, item_counter:, item_iteration:)
        @item = item
        @counter = item_counter
        @iteration = item_iteration
      end

      def call
        "<p>#{@item.name} #{@counter} #{@iteration.last?}</p>".html_safe
      end
    end

    class ForwardAllArgumentsComponent < ForwardedCounterComponent
      prepend ForwardAllArguments
    end

    class ForwardAnonymousSplatsComponent < ForwardedCounterComponent
      prepend ForwardAnonymousSplats
    end

    def test_collection_counter_through_prepended_argument_forwarding
      render_inline(ForwardAllArgumentsComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 0 false")
      assert_selector("p", text: "Mints 1 true")
    end

    def test_collection_counter_through_prepended_anonymous_splats
      render_inline(ForwardAnonymousSplatsComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 0 false")
      assert_selector("p", text: "Mints 1 true")
    end

    class ForwardingChildComponent < ForwardedCounterComponent
      def initialize(**)
        super
      end
    end

    class ForwardingGrandchildComponent < ForwardingChildComponent
      def initialize(...)
        super
      end
    end

    def test_collection_counter_through_subclasses_forwarding_to_super
      render_inline(ForwardingGrandchildComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 0 false")
      assert_selector("p", text: "Mints 1 true")
    end

    module ConsumeCounter
      def initialize(*, item_counter:, **)
        @counter = item_counter
        super(*, **)
      end
    end

    class ConsumedCounterComponent < ViewComponent::Base
      prepend ConsumeCounter

      with_collection_parameter :item

      def initialize(item:)
        @item = item
      end

      def call
        "<p>#{@item.name} #{@counter}</p>".html_safe
      end
    end

    def test_collection_counter_consumed_by_prepended_module
      render_inline(ConsumedCounterComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 0")
      assert_selector("p", text: "Mints 1")
    end

    class NarrowedCounterComponent < ForwardedCounterComponent
      def initialize(item:)
        super(item:, item_counter: 99, item_iteration: ActionView::PartialIteration.new(1))
      end
    end

    def test_collection_counter_not_passed_to_subclass_that_narrows_initialize
      render_inline(NarrowedCounterComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 99 true")
      assert_selector("p", text: "Mints 99 true")
    end

    class ForwardedMissingParameterComponent < ViewComponent::Base
      prepend ForwardAllArguments

      def initialize(name:)
        @name = name
      end

      def call
        @name
      end
    end

    def test_prepended_argument_forwarding_does_not_skip_collection_parameter_validation
      assert_raises(ViewComponent::MissingCollectionArgumentError) do
        render_inline(ForwardedMissingParameterComponent.with_collection(@products))
      end
    end

    class ForwardedReservedParameterComponent < ViewComponent::Base
      prepend ForwardAllArguments

      def initialize(content:)
        @content = content
      end

      def call
        ""
      end
    end

    def test_prepended_argument_forwarding_does_not_skip_reserved_parameter_validation
      with_new_cache do
        assert_raises(ViewComponent::ReservedParameterError) do
          ForwardedReservedParameterComponent.__vc_compile(raise_errors: true)
        end
      end
    end

    module ConsumeOptions
      def initialize(*, **options)
        @options = options
        super()
      end
    end

    class ConsumedOptionsComponent < ViewComponent::Base
      prepend ConsumeOptions

      def call
        "<p>#{@options[:consumed_options].name}</p>".html_safe
      end
    end

    def test_prepended_named_keyword_splat_accepts_collection_parameter
      render_inline(ConsumedOptionsComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock")
      assert_selector("p", text: "Mints")
    end

    def test_collection_arguments_are_ractor_shareable
      ForwardedCounterComponent.__vc_compile

      assert Ractor.shareable?(ForwardedCounterComponent.send(:__vc_collection_arguments))
    end

    class RecompiledCounterComponent < ViewComponent::Base
      with_collection_parameter :item

      def initialize(item:)
        @item = item
      end

      def call
        "<p>#{@item.name} #{@counter}</p>".html_safe
      end
    end

    def test_recompiling_refreshes_collection_arguments
      render_inline(RecompiledCounterComponent.with_collection(@products))
      RecompiledCounterComponent.prepend(ConsumeCounter)
      RecompiledCounterComponent.__vc_compile(force: true)

      render_inline(RecompiledCounterComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock 0")
      assert_selector("p", text: "Mints 1")
    end

    class DefaultParameterParentComponent < ViewComponent::Base
      def initialize(**)
      end

      def call
        ""
      end
    end

    def test_subclass_defined_after_parent_renders_uses_its_own_collection_parameter
      render_inline(DefaultParameterParentComponent.with_collection(@products))

      self.class.class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
        class DefaultParameterChildComponent < DefaultParameterParentComponent
          def initialize(default_parameter_child:)
            @product = default_parameter_child
          end

          def call
            "<p>\#{@product.name}</p>".html_safe
          end
        end
      RUBY

      assert_equal :default_parameter_child, DefaultParameterChildComponent.__vc_collection_parameter

      render_inline(DefaultParameterChildComponent.with_collection(@products))

      assert_selector("p", text: "Radio clock")
      assert_selector("p", text: "Mints")
    end

    class ReservedParameterParentComponent < ViewComponent::Base
      def initialize(title:, content: nil)
      end

      def call
        ""
      end
    end

    class NamedKeywordSplatChildComponent < ReservedParameterParentComponent
      def initialize(**options)
        super(title: options[:title])
      end
    end

    class AnonymousKeywordSplatChildComponent < ReservedParameterParentComponent
      def initialize(**)
        super
      end
    end

    def test_keyword_splat_subclass_raises_for_reserved_parameter_in_parent
      assert_raises(ViewComponent::ReservedParameterError) do
        NamedKeywordSplatChildComponent.__vc_validate_initialization_parameters!
      end

      assert_raises(ViewComponent::ReservedParameterError) do
        AnonymousKeywordSplatChildComponent.__vc_validate_initialization_parameters!
      end
    end
  end
end
