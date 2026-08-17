# frozen_string_literal: true

require "test_helper"

class RenderingAllocationsTest < ViewComponent::TestCase
  INLINE_ALLOCATIONS = {
    ["7.1", "3.2"] => 45,
    ["7.2", "3.3"] => 45,
    ["8.0", "3.4"] => 37,
    ["8.1", "4.0"] => 35,
    ["8.1", "4.1"] => 35,
    ["8.2", "4.0"] => 54,
    ["8.2", "4.1"] => 54
  }.freeze

  COLLECTION_ALLOCATIONS = {
    ["7.1", "3.2"] => 87,
    ["7.2", "3.3"] => 88,
    ["8.0", "3.4"] => 76,
    ["8.1", "4.0"] => 61,
    ["8.1", "4.1"] => 61,
    ["8.2", "4.0"] => 79,
    ["8.2", "4.1"] => 79
  }.freeze

  class TestController < IntegrationExamplesController
    def view_assigns
      {}
    end
  end

  def vc_test_controller_class
    TestController
  end

  def without_debug_event_reporting
    reporter = ActiveSupport.event_reporter if ActiveSupport.respond_to?(:event_reporter)
    return yield unless reporter

    debug_mode = reporter.debug_mode?
    reporter.debug_mode = false
    yield
  ensure
    reporter.debug_mode = debug_mode if reporter
  end

  def test_render_inline_allocations
    # Stabilize compilation status ahead of testing allocations to simulate rendering
    # performance with compiled component
    ViewComponent::CompileCache.cache.delete(MyComponent)
    MyComponent.__vc_ensure_compiled

    # Ensure any one-time render allocations are done.
    render_inline(MyComponent.new)

    without_debug_event_reporting do
      with_instrumentation_enabled_option(false) do
        assert_versioned_allocations(INLINE_ALLOCATIONS) do
          render_inline(MyComponent.new)
        end
      end
    end

    assert_selector("div", text: "hello,world!")
  end

  def test_render_collection_inline_allocations
    # Stabilize compilation status ahead of testing allocations to simulate rendering
    # performance with compiled component
    ViewComponent::CompileCache.cache.delete(ProductComponent)
    ProductComponent.__vc_ensure_compiled

    products = [Product.new(name: "Radio clock"), Product.new(name: "Mints")]
    notice = "On sale"
    # Ensure any one-time render allocations are done.
    render_inline(ProductComponent.with_collection(products, notice: notice))

    without_debug_event_reporting do
      with_instrumentation_enabled_option(false) do
        assert_versioned_allocations(COLLECTION_ALLOCATIONS) do
          render_inline(ProductComponent.with_collection(products, notice: notice))
        end
      end
    end

    assert_selector("h1", text: "Product", count: 2)
  end
end
