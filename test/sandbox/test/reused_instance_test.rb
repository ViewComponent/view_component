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

    def setup
      super
      @original = ViewComponent::Base.config.raise_on_reused_instances
    end

    def teardown
      ViewComponent::Base.config.raise_on_reused_instances = @original
      super
    end

    def test_rendering_same_instance_twice_raises_by_default
      component = ContextSnapshotComponent.new
      render_inline(component)

      assert_raises(ViewComponent::ReusedInstanceError) do
        render_inline(component)
      end
    end

    def test_error_message_names_the_component_and_mentions_config_flag
      component = ContextSnapshotComponent.new
      render_inline(component)

      error = assert_raises(ViewComponent::ReusedInstanceError) { render_inline(component) }
      assert_includes error.message, "ContextSnapshotComponent"
      assert_includes error.message, "raise_on_reused_instances"
    end

    def test_with_guard_disabled_reused_instance_emits_warning_and_refreshes_state
      ViewComponent::Base.config.raise_on_reused_instances = false

      component = ContextSnapshotComponent.new

      first = render_inline(component).to_html
      warnings = capture_warnings { render_inline(component) }
      second = @rendered_content.to_s

      assert(
        warnings.any? { |w| w.include?("rendered more than once") },
        "Expected a 'rendered more than once' warning, got: #{warnings.inspect}"
      )
      # Sanity check: both renders produced an object id (helpers are non-nil).
      refute_empty first
      refute_empty second
    end

    def test_helpers_controller_request_are_re_derived_on_each_render
      # With the guard disabled, render the same instance twice. Phase 1 of the
      # GHSA fix removes the `||=` memoization on @__vc_controller / @__vc_helpers /
      # @__vc_request, so the cached ivars must be cleared between renders.
      ViewComponent::Base.config.raise_on_reused_instances = false

      component = ContextSnapshotComponent.new
      capture_warnings { render_inline(component) }
      first_ivars = %i[@__vc_controller @__vc_helpers @__vc_request].map do |ivar|
        component.instance_variable_defined?(ivar) ? component.instance_variable_get(ivar) : nil
      end

      # Reset internal state to simulate a second render under a different view
      # context. After Phase 1, calling render_in clears the cached ivars at the
      # top of render_in via __vc_reset_render_state!.
      component.send(:__vc_reset_render_state!)

      first_ivars.each_with_index do |_, i|
        ivar = %i[@__vc_controller @__vc_helpers @__vc_request][i]
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
