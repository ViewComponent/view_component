# frozen_string_literal: true

require "action_view/renderer/collection_renderer"
require "action_view/helpers/output_safety_helper"

module ViewComponent
  class Collection
    include Enumerable
    include ActionView::Helpers::OutputSafetyHelper

    attr_reader :component

    delegate :size, to: :@collection

    EMPTY_SPACER = "".html_safe.freeze
    private_constant :EMPTY_SPACER

    def render_in(view_context, **_, &block)
      rendered = components.map! do |component|
        component.render_in(view_context, &block)
      end
      safe_join(rendered, rendered_spacer(view_context))
    end

    def each(&block)
      components.each(&block)
    end

    if defined?(Rails::VERSION) && Rails::VERSION::MAJOR == 7 && Rails::VERSION::MINOR == 1
      # Rails expects us to define `format` on all renderables,
      # but we do not know the `format` of a ViewComponent until runtime.
      def format
        nil
      end
    end

    private

    # Always rebuild child component instances per render to avoid leaking
    # request-scoped state from a previous render into a later one (GHSA).
    def components
      component.__vc_validate_collection_parameter!(validate_default: true)

      collection_param = component.__vc_collection_parameter
      counter_present = component.__vc_counter_argument_present?
      counter_param = component.__vc_collection_counter_parameter if counter_present
      iteration_present = component.__vc_iteration_argument_present?
      iteration_param = component.__vc_collection_iteration_parameter if iteration_present
      iterator = ActionView::PartialIteration.new(@collection.size) if counter_present || iteration_present
      item_options = @options.dup

      @collection.map do |item|
        item_options[collection_param] = item
        item_options[counter_param] = iterator.index if counter_present
        item_options[iteration_param] = iterator.dup if iteration_present
        instance = component.new(**item_options)
        iterator&.iterate!
        instance
      end
    end

    def initialize(component, object, spacer_component, options = {})
      @component = component
      @collection = collection_variable(object || [])
      @spacer_component = spacer_component
      @options = options
    end

    def collection_variable(object)
      if object.respond_to?(:to_ary)
        object.to_ary
      else
        raise InvalidCollectionArgumentError
      end
    end

    # Keep the caller's spacer unrendered, including its nested slot components.
    def rendered_spacer(view_context)
      return EMPTY_SPACER unless @spacer_component

      spacer = @spacer_component.is_a?(Base) ? @spacer_component.__vc_dup_for_render : @spacer_component.dup
      spacer.render_in(view_context)
    end
  end
end
