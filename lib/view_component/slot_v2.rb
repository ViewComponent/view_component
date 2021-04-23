# frozen_string_literal: true

require "view_component/with_content_helper"

module ViewComponent
  class SlotV2
    include ViewComponent::WithContentHelper

    attr_writer :_component_instance, :_content_block, :_content

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
      return @content if defined?(@content)

      view_context = @parent.send(:view_context)

      raise ArgumentError.new("Block provided after calling `with_content`. Use one or the other.") if defined?(@_content_block) && defined?(@_content_set_by_with_content)

      @content = if defined?(@_component_instance)
        if defined?(@_content_set_by_with_content)
          @_component_instance.with_content(@_content_set_by_with_content)

          view_context.capture do
            @_component_instance.render_in(view_context)
          end
        elsif defined?(@_content_block)
          view_context.capture do
            # render_in is faster than `parent.render`
            @_component_instance.render_in(view_context, &@_content_block)
          end
        else
          view_context.capture do
            @_component_instance.render_in(view_context)
          end
        end
      elsif defined?(@_content)
        @_content
      elsif defined?(@_content_block)
        view_context.capture(&@_content_block)
      elsif defined?(@_content_set_by_with_content)
        @_content_set_by_with_content
      end

      @content
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

    def html_safe?
      to_s.html_safe?
    end

    def respond_to_missing?(symbol, include_all = false)
      defined?(@_component_instance) && @_component_instance.respond_to?(symbol, include_all)
    end
  end
end
