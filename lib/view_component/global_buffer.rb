# frozen_string_literal: true

module ViewComponent
  # TODO if things break, log each time an unsafe string method is called
  class GlobalBuffer
    def initialize(buffer)
      @_buffer = buffer
    end

    def __swap_buffer__(buffer)
      # TODO remove once this is debugged
      raise 'oh no' if buffer.kind_of?(GlobalBuffer)
      @_buffer = buffer
    end

    def __buffer__
      @_buffer
    end

    def to_s
      @_buffer.to_s
    end

    def html_safe?
      @_buffer.html_safe?
    end

    # Necessary for cases like `output_buffer = output_buffer.class.new(output_buffer)` (yes, this happens)
    def class
      @_buffer.class
    end

    def method_missing(symbol, *args, **kwargs)
      @_buffer.send(symbol, *args, **kwargs)
    end
    ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

    def respond_to_missing?(symbol, include_all)
      @_buffer.respond_to?(symbol, include_all) || super
    end

    module Patch
      extend ActiveSupport::Concern

      module SeparateGlobalModuleForHAMLCompat
        def output_buffer=(new_buf)
          # TODO make HAML work by falling back to super
          @output_buffer.__swap_buffer__(new_buf)
        end

        def with_output_buffer(buf = nil) # :nodoc:
          $count ||= 0
          $count += 1
          unless buf
            buf = ActionView::OutputBuffer.new
            if output_buffer && output_buffer.respond_to?(:encoding)
              buf.force_encoding(output_buffer.encoding)
            end
          end

          old_buffer = output_buffer.__buffer__
          @output_buffer.__swap_buffer__(buf)
          yield
          @output_buffer.__buffer__
        ensure
          @output_buffer.__swap_buffer__(old_buffer)
        end
      end

      included do
        alias_method(:original_output_buffer=, :output_buffer=)
        prepend SeparateGlobalModuleForHAMLCompat

        alias_method(:original_with_output_buffer, :with_output_buffer)
      end
    end
  end
end
