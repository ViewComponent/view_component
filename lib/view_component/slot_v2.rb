# frozen_string_literal: true

module ViewComponent
  class SlotV2
    attr_writer :_component_instance, :_content_block, :_content,
                :_renderable_function, :_args, :_kwargs

    def initialize(parent)
      @parent = parent
    end

    # Used to render the slot content in the template
    #
    # There's currently 3 different values that may be set, that we can render.
    #
    # If the slot renderable is a component, the string class name of a
    # component, or a function that returns a component, we render that
    # component instance, returning the string.
    #
    # If the slot renderable is a function and returns a string, it is
    # set as `@_content` and is returned directly.
    #
    # If there is no slot renderable, we evaluate the block passed to
    # the slot and return it.
    def to_s
      view_context = @parent.send(:view_context)
      view_context.capture do
        if defined?(@_component_instance)
          # render_in is faster than `parent.render`
          @_component_instance.render_in(view_context, &@_content_block)
        elsif defined?(@_content)
          @_content
        elsif defined?(@_content_block)
          @_content_block.call
        end
      end
    end

    # Allow access to public component methods via the wrapper
    #
    # e.g.
    #
    # calling `header.name` (where `header` is a slot) will call `name`
    # on the `HeaderComponent` instance.
    #
    # Where the component may look like:
    #
    # class MyComponent < ViewComponent::Base
    #   has_one :header, HeaderComponent
    #
    #   class HeaderComponent < ViewComponent::Base
    #     def name
    #       @name
    #     end
    #   end
    # end
    #
    def method_missing(symbol, *args, &block)
      @_component_instance.public_send(symbol, *args, &block)
    end

    def respond_to_missing?(symbol, include_all = false)
      defined?(@_component_instance) && @_component_instance.respond_to?(symbol, include_all)
    end

    # Instantiate a concrete slot from a generic one, passing extra component parameters
    def with(*args, **kwargs)
      return self if args.empty? && kwargs.empty?

      slot = self.class.new(@parent)

      slot._args = args = [*args, *@_args]
      slot._kwargs = kwargs = {**kwargs, **@_kwargs}

      slot._component_instance =
        if @_renderable_function
          @_renderable_function.bind(@parent).call(*args, **kwargs, &@_content_block)
        else
          @_component_instance.class.new(*args, **kwargs)
        end

      slot._content_block = @_content_block
      slot._renderable_function = @_renderable_function

      slot
    end
  end
end
