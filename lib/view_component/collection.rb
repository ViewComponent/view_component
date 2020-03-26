
# frozen_string_literal: true

module ViewComponent
  class Collection
    def render_in(view_context, &block)
      as = as_variable(@component, @options)
      collection = collection_variable(@object, @options)
      args = @options.except(:collection, :as)

      collection.map do |item|
        @component.new(args.merge(as => item)).render_in(view_context, &block)
      end.join
    end

    private

    def initialize(component, object = nil, options)
      @component = component
      @object = object
      @options = options
    end

    def collection_variable(object, options)
      if object.respond_to?(:to_ary)
        object.to_ary
      elsif options.key?(:collection)
        collection = options[:collection]
        collection ? collection.to_a : []
      else
        raise ArgumentError.new("Must specify the option `collection` or pass a valid collection object.")
      end
    end

    # Copied from https://github.com/rails/rails/blob/e2cf0b1d780b2e09f5270249ca021d94ce4fff9d/actionview/lib/action_view/renderer/partial_renderer.rb
    def as_variable(component, options)
      if as = options[:as]
        raise_invalid_option_as(as) unless /\A[a-z_]\w*\z/.match?(as.to_s)
        as.to_sym
      else
        component.name.demodulize.underscore.chomp("_component").to_sym
      end
    end

    OPTION_AS_ERROR_MESSAGE  = "The value (%s) of the option `as` is not a valid Ruby identifier; " \
                                "make sure it starts with lowercase letter, " \
                                "and is followed by any combination of letters, numbers and underscores."

    def raise_invalid_option_as(as)
      raise ArgumentError.new(OPTION_AS_ERROR_MESSAGE % (as))
    end
  end
end
