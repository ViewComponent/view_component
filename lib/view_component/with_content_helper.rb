# frozen_string_literal: true

module ViewComponent
  module WithContentHelper
    def with_content(value = nil, &block)
      if value && block
        raise ArgumentError.new("Content provided in two ways, using both an argument and a block. Use one or the other.")
      elsif value.nil? && block.nil?
        raise ArgumentError.new("No content provided. Provide as an argument or a block.")
      elsif block
        @_content_set_by_with_content = block
      else
        @_content_set_by_with_content = -> (_component) { value }
      end

      self
    end

    # Renders the given object and returns the result, if object can be rendered.
    # Otherwise, returns object.
    def render_or_return(object)
      if object.respond_to?(:render_in)
        render(object)
      else
        object
      end
    end
  end
end
