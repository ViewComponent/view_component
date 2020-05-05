# frozen_string_literal: true

module ViewComponent
  class Collection
    def render_in(view_context, &block)
      iterator = ActionView::PartialIteration.new(@collection.size)

      ensure_initializer_accepts_iterator
      @component.compile!
      @collection.map do |item|
        content = @component.new(component_options(item, iterator)).render_in(view_context, &block)
        iterator.iterate!
        content
      end.join.html_safe
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
        raise ArgumentError.new("The value of the argument isn't a valid collection. Make sure it responds to to_ary: #{object.inspect}")
      end
    end

    def component_options(item, iterator)
      item_options = { @component.collection_parameter_name => item }
      item_options[@component.collection_counter_parameter_name] = iterator.index + 1 if @component.counter_argument_present?

      @options.merge(item_options)
    end

    def ensure_initializer_accepts_iterator
      # If the component does not set a custom collection parameter,
      # make sure the default parameter is accepted by the
      # component initializer.
      if !@component.with_collection_parameter_attr &&
        !@component.instance_method(:initialize).parameters.map(&:last).include?(@component.collection_parameter_name)
        raise ArgumentError.new(
          "#{@component} initializer must accept " \
          "`#{@component.collection_parameter_name}` collection parameter."
        )
      end
    end
  end
end
