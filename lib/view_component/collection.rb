# frozen_string_literal: true

require "action_view/renderer/collection_renderer"
require "action_view/helpers/output_safety_helper"

module ViewComponent
  class Collection
    include Enumerable
    include ActionView::Helpers::OutputSafetyHelper

    attr_reader :component

    delegate :size, to: :@collection

    def render_in(view_context, **_, &block)
      rendered = components.map do |component|
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
      iterator = ActionView::PartialIteration.new(@collection.size)

      component.__vc_validate_collection_parameter!(validate_default: true)

      @collection.map do |item|
        component.new(**component_options(item, iterator)).tap do |_|
          iterator.iterate!
        end
      end
    end

    def initialize(component, object, spacer_component, **options)
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

    def component_options(item, iterator)
      item_options = {component.__vc_collection_parameter => item}
      item_options[component.__vc_collection_counter_parameter] = iterator.index if component.__vc_counter_argument_present?
      item_options[component.__vc_collection_iteration_parameter] = iterator.dup if component.__vc_iteration_argument_present?

      @options.merge(item_options)
    end

    # Render the spacer through a fresh `dup` so a collection rendered multiple
    # times always gets a clean spacer instance.
    def rendered_spacer(view_context)
      return "" unless @spacer_component

      @spacer_component.dup.render_in(view_context)
    end
  end
end
