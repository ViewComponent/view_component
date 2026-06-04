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

    def test_rendering_same_instance_twice_does_not_raise_and_refreshes_state
      component = ContextSnapshotComponent.new

      first = render_inline(component).to_html

      assert_nothing_raised do
        render_inline(component)
      end

      second = @rendered_content.to_s
      refute_empty first
      refute_empty second
    end

    def test_render_state_ivars_are_cleared_between_renders
      component = ContextSnapshotComponent.new
      render_inline(component)

      component.send(:__vc_reset_render_state!)

      %i[@__vc_controller @__vc_helpers @__vc_request @__vc_original_view_context].each do |ivar|
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
