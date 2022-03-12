# frozen_string_literal: true

module ViewComponent
  class OutputBufferStack
    delegate_missing_to :@current_buffer
    delegate :presence, :present?, :html_safe?, to: :@current_buffer

    attr_reader :buffer_stack

    def self.make_frame(*args)
      ActionView::OutputBuffer.new(*args)
    end

    def initialize(initial_buffer = nil)
      if initial_buffer.is_a?(self.class)
        @current_buffer = self.class.make_frame(initial_buffer.current)
        @buffer_stack = [*initial_buffer.buffer_stack[0..-2], @current_buffer]
      else
        @current_buffer = initial_buffer || self.class.make_frame
        @buffer_stack = [@current_buffer]
      end
    end

    def replace(buffer)
      return if self == buffer

      @current_buffer = buffer.current
      @buffer_stack = buffer.buffer_stack
    end

    def append=(arg)
      @current_buffer.append = arg
    end

    def safe_append=(arg)
      @current_buffer.safe_append = arg
    end

    def safe_concat(arg)
      # rubocop:disable Rails/OutputSafety
      @current_buffer.safe_concat(arg)
      # rubocop:enable Rails/OutputSafety
    end

    def length
      @current_buffer.length
    end

    def push(buffer = nil)
      buffer ||= self.class.make_frame
      @buffer_stack.push(buffer)
      @current_buffer = buffer
    end

    def pop
      @buffer_stack.pop.tap do
        @current_buffer = @buffer_stack.last
      end
    end

    def to_s
      @current_buffer
    end

    alias_method :current, :to_s
  end
end
