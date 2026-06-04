# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class ReusedInstanceTest < TestCase
    class ContextSnapshotComponent < ViewComponent::Base
      with_collection_parameter :item

      def initialize(item: nil)
        @item = item
      end

      def call
        helpers.object_id.to_s.html_safe
      end
    end

    def test_rendering_same_instance_twice_does_not_leak_state
      component = ContextSnapshotComponent.new

      first = render_inline(component).to_html
      second = render_inline(component).to_html

      refute_empty first
      refute_empty second
    end

    def test_helpers_controller_request_are_re_derived_on_each_render
      # `render_in` must clear the cached `@__vc_controller` / `@__vc_helpers` /
      # `@__vc_request` ivars between renders, otherwise a reused instance
      # leaks request-scoped state from a previous render.
      component = ContextSnapshotComponent.new
      render_inline(component)

      component.send(:__vc_reset_render_state!)

      %i[@__vc_controller @__vc_helpers @__vc_request].each do |ivar|
        refute(
          component.instance_variable_defined?(ivar),
          "Expected #{ivar} to be cleared by __vc_reset_render_state!, but it is still defined"
        )
      end
    end

    def test_rendering_same_collection_twice_does_not_raise
      collection = ContextSnapshotComponent.with_collection([1, 2, 3])
      render_inline(collection)

      assert_nothing_raised do
        render_inline(collection)
      end
    end

    def test_collection_with_spacer_component_can_be_rendered_twice
      spacer = ContextSnapshotComponent.new
      collection = ContextSnapshotComponent.with_collection([1, 2], spacer_component: spacer)

      render_inline(collection)
      assert_nothing_raised do
        render_inline(collection)
      end
    end
  end
end
