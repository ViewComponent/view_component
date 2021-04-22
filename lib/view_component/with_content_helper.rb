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
  end
end
