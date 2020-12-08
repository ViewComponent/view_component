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
        @content_set_by_with_content = block
      else
        @content_set_by_with_content = -> (_slot) { value }
      end

      self
    end

    def content
      return @content if defined?(@content)
      return unless defined?(@content_set_by_with_content)

      @content = @content_set_by_with_content.call(self)
    end
  end
end
