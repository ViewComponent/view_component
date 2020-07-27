# frozen_string_literal: true

module ViewComponent
  class SubComponentWrapper
    attr_writer :_component_instance, :_content_block, :_content

    # Parent must be `nil` for v1
    def initialize(parent = nil)
      @parent = parent
    end

    # Used to render the subcomponent content in the template
    #
    # There's currently 3 different values that may be set, that we can render.
    #
    # If the subcomponent renderable is a component, the string class name of a
    # component, or a function that returns a component, we render that
    # component instance, returning the string.
    #
    # If the subcomponent renderable is a function and returns a string, it is
    # set as `@_content` and is returned directly.
    #
    # If there is no subcomponent renderable, we evaluate the block passed to
    # the subcomponent and return it (content area style)
    def to_s
      if defined?(@_component_instance)
        # render_in is faster than `parent.render`
        @_component_instance.render_in(
          @parent.send(:view_context),
          &@_content_block
        )
      elsif defined?(@_content)
        @_content
      elsif defined?(@_content_block)
        @_content_block.call
      end
    end

    # This allows access to public component methods via the wrapper
    #
    # e.g.
    #
    # calling `header.name` (where `header` is a subcomponent) will call `name`
    # on the `HeaderComponent` instance
    #
    # Where the component may includes:
    #
    # has_one :header, HeaderComponent
    #
    # class HeaderComponent < ViewComponent::Base
    #   def name
    #     @name
    #   end
    # end
    #
    def method_missing(symbol, *args, &block)
      @_component_instance.public_send(symbol, *args, &block)
    end
  end
end
