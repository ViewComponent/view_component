
# frozen_string_literal: true

module ViewComponent
  class Collection
    def render_in(view_context, &block)
      as = @component.collection_parameter_name

      @collection.map do |item|
        @component.new(@options.merge(as => item)).render_in(view_context, &block)
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
  end
end
