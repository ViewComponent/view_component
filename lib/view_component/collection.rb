# frozen_string_literal: true

module ViewComponent
  class Collection

    def render_in(view_context, &block)
      as        = @component.collection_parameter_name
      iteration = CollectionIteration.new(@collection.size)

      @collection.map do |item|
        iteration.iterate!

        component = @component.new(@options.merge(as => item))
        component.send("#{iteration_attribute}=", iteration)
        component.render_in(view_context, &block)
      end.join.html_safe
    end

    private

    attr_reader :iteration_attribute

    def initialize(component, object, **options)
      @component           = component
      @collection          = collection_variable(object || [])
      @options             = options
      @iteration_attribute = :"#{@component.collection_parameter_name}_iteration"

      @component.send(:attr_accessor, @iteration_attribute)
    end

    def collection_variable(object)
      if object.respond_to?(:to_ary)
        object.to_ary
      else
        raise ArgumentError.new("The value of the argument isn't a valid collection. Make sure it responds to to_ary: #{object.inspect}")
      end
    end
  end
end
