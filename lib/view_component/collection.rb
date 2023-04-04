# frozen_string_literal: true

require "action_view/renderer/collection_renderer" if Rails.version.to_f >= 6.1

module ViewComponent
  class Collection
    include Enumerable
    attr_reader :component

    delegate :format, to: :component
    delegate :size, to: :@collection

    attr_accessor :__vc_original_view_context

    def set_original_view_context(view_context)
      self.__vc_original_view_context = view_context
    end

    def render_in(view_context, &block)
      components.map do |component|
        component.set_original_view_context(__vc_original_view_context)
        component.render_in(view_context, &block)
      end.join.html_safe
    end

    def components
      return @components if defined? @components

      iterator = ActionView::PartialIteration.new(@collection.size)

      component.validate_collection_parameter!(validate_default: true)

      @components = @collection.map do |item|
        component.new(**component_options(item, iterator)).tap do |component|
          iterator.iterate!
        end
      end
    end

    def each(&block)
      components.each(&block)
    end

    private

    def initialize(component, object, **options)
      @component = component
      @collection = collection_variable(object || [])
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
      item_options = {component.collection_parameter => item}
      item_options[component.collection_counter_parameter] = iterator.index if component.counter_argument_present?
      item_options[component.collection_iteration_parameter] = iterator.dup if component.iteration_argument_present?

      @options.merge(item_options)
    end
  end
end
