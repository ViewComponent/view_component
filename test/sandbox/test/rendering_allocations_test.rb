# frozen_string_literal: true

require "test_helper"

class RenderingAllocationsTest < ViewComponent::TestCase
  INLINE_ALLOCATIONS = {
    ["7.1", "3.2"] => 54,
    ["7.2", "3.3"] => 49,
    ["8.0", "3.4"] => 43,
    ["8.1", "4.0"] => 41,
    ["8.1", "4.1"] => 41,
    ["8.2", "4.0"] => 128,
    ["8.2", "4.1"] => 128
  }.freeze

  COLLECTION_ALLOCATIONS = {
    ["7.1", "3.2"] => 101,
    ["7.2", "3.3"] => 97,
    ["8.0", "3.4"] => 89,
    ["8.1", "4.0"] => 74,
    ["8.1", "4.1"] => 74,
    ["8.2", "4.0"] => 161,
    ["8.2", "4.1"] => 161
  }.freeze

  def vc_test_controller_class
    IntegrationExamplesController
  end

  def test_render_inline_allocations
    # Stabilize compilation status ahead of testing allocations to simulate rendering
    # performance with compiled component
    ViewComponent::CompileCache.cache.delete(MyComponent)
    MyComponent.__vc_ensure_compiled

    # Ensure any one-time render allocations are done.
    render_inline(MyComponent.new)

    with_instrumentation_enabled_option(false) do
      assert_versioned_allocations(INLINE_ALLOCATIONS) do
        render_inline(MyComponent.new)
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

    with_instrumentation_enabled_option(false) do
      assert_versioned_allocations(COLLECTION_ALLOCATIONS) do
        render_inline(ProductComponent.with_collection(products, notice: notice))
      end
    end

    assert_selector("h1", text: "Product", count: 2)
  end
end
