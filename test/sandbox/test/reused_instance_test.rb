# frozen_string_literal: true

require "test_helper"

module ViewComponent
  class ReusedInstanceTest < TestCase
    # A component that surfaces the per-render `view_context` identity so we can
    # assert that the *current* render's context is used, not a stale one.
    class ContextSnapshotComponent < ViewComponent::Base
      with_collection_parameter :item

      def initialize(item: nil)
        @item = item
      end

      def call
        helpers.object_id.to_s.html_safe
      end
    end

    # A component with a `with_content`-settable body, used to prove that
    # content set once cannot leak into a later render of the same instance.
    class BodyComponent < ViewComponent::Base
      def call
        content.to_s.html_safe
      end
    end

    # A component with a slot, used to prove that slot content set once
    # cannot leak into a later render of the same instance.
    class HeaderComponent < ViewComponent::Base
      renders_one :title

      def call
        "<h1>#{title}</h1>".html_safe
      end
    end

    def test_rendering_same_instance_twice_raises
      component = ContextSnapshotComponent.new
      render_inline(component)

      assert_raises(ViewComponent::ReusedInstanceError) do
        render_inline(component)
      end
    end

    def test_error_message_names_the_component
      component = ContextSnapshotComponent.new
      render_inline(component)

      error = assert_raises(ViewComponent::ReusedInstanceError) { render_inline(component) }
      assert_includes error.message, "ContextSnapshotComponent"
      assert_includes error.message, "single-use"
    end

    def test_reused_instance_with_with_content_raises
      # Regression test for GHSA-8qw7-6phv-7q6p: `with_content` state is
      # populated by the caller before `render_in`, so it isn't cleared by
      # `__vc_reset_render_state!`. The reused-instance guard is what prevents
      # the first render's `with_content` value from leaking into a second
      # render of the same instance.
      component = BodyComponent.new.with_content("user_a_secret")
      render_inline(component)

      assert_raises(ViewComponent::ReusedInstanceError) do
        render_inline(component)
      end
    end

    def test_reused_instance_with_slot_raises
      # Regression test for GHSA-8qw7-6phv-7q6p: slot state (`@__vc_set_slots`
      # and the memoized `@content` on each `Slot`) survives across renders,
      # so the guard is what prevents leaking one user's slot content into
      # another user's render of the same instance.
      component = HeaderComponent.new
      component.with_title { "user_a_name" }
      render_inline(component)

      assert_raises(ViewComponent::ReusedInstanceError) do
        render_inline(component)
      end
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
      # Collection rebuilds child components per render, so the same Collection
      # object can be safely rendered twice (each child instance is fresh).
      collection = ContextSnapshotComponent.with_collection([1, 2, 3])
      render_inline(collection)

      assert_nothing_raised do
        render_inline(collection)
      end
    end

    def test_collection_with_spacer_component_can_be_rendered_twice
      # The spacer is the only instance the Collection holds long-term. The
      # spacer must be re-renderable across collection renders (Collection dups
      # it before each render to avoid tripping the single-render guard).
      spacer = ContextSnapshotComponent.new
      collection = ContextSnapshotComponent.with_collection([1, 2], spacer_component: spacer)

      render_inline(collection)
      assert_nothing_raised do
        render_inline(collection)
      end
    end
  end
end
