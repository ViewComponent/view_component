# frozen_string_literal: true

module ViewComponent
  class Collection

    def render_in(view_context, &block)
      iterator = ActionView::PartialIteration.new(@collection.size)

      @collection.map do |item|
        content = @component.new(component_options(item, iterator)).render_in(view_context, &block)
        iterator.iterate!
        content
      end.join.html_safe
    end

    private

    def initialize(component, object, **options)
      @component  = component
      @collection = collection_variable(object || [])
      @options    = options
    end

    def collection_variable(object)
      if object.respond_to?(:to_ary)
        object.to_ary
      else
        raise ArgumentError.new("The value of the argument isn't a valid collection. Make sure it responds to to_ary: #{object.inspect}")
      end
    end

    def collection_parameter_name
      @component.collection_parameter_name
    end

    def collection_counter_parameter_name
      "#{collection_parameter_name}_counter".to_sym
    end

    def component_options(item, iterator)
      item_options = { collection_parameter_name => item }
      item_options[collection_counter_parameter_name] = iterator.index + 1 if counter_argument_present?

      @options.merge(item_options)
    end

    def counter_argument_present?
      @_counter_argument_present ||= @component.instance_method(:initialize).parameters.map(&:second).include?(collection_counter_parameter_name)
    end
  end
end
