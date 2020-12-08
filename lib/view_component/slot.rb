# frozen_string_literal: true

module ViewComponent
  class Slot
    attr_writer :content

    def with_content(value = nil, &block)
      if value && block
        raise ArgumentError.new("Content provided in two ways, using both an argument and a block. Use one or the other.")
      elsif value.nil? && block.nil?
        raise ArgumentError.new("No content provided. Provide as an argument or a block.")
      elsif block
        @with_content_block = block
      else
        @with_content_value = value
      end

      self
    end

    def content
      return @content if defined?(@content)
      return unless defined?(@with_content_block) || defined?(@with_content_value)

      @content =
        if @with_content_block
          @with_content_block.call(self)
        else
          @with_content_value
        end
    end
  end
end
