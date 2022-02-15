# frozen_string_literal: true

module ViewComponent
  # TODO if things break, log each time an unsafe string method is called
  module GlobalBuffer
    class Coordinator
      def initialize
        @subscribers = []
      end

      def subscribers
        @subscribers
      end
    end

    module Patch
      extend ActiveSupport::Concern
      module Compatibility
        def with_output_buffer(buf = nil) # :nodoc:
          unless buf
            buf = ActionView::OutputBuffer.new
            if output_buffer && output_buffer.respond_to?(:encoding)
              buf.force_encoding(output_buffer.encoding)
            end
          end
          self.output_buffer, old_buffer = buf, output_buffer
          global_buffer_coordinator&.subscribers&.each { |s| s.output_buffer = buf}
          yield
          output_buffer
        ensure
          self.output_buffer = old_buffer
          global_buffer_coordinator&.subscribers&.each { |s| s.output_buffer = old_buffer }
        end

        def _run(method, template, locals, buffer, add_to_stack: true, &block)
          _old_output_buffer, _old_virtual_path, _old_template = @output_buffer, @virtual_path, @current_template
          @current_template = template if add_to_stack
          @output_buffer = buffer
          global_buffer_coordinator&.subscribers&.each { |s| s.output_buffer = buffer }
          public_send(method, locals, buffer, &block)
        ensure
          @output_buffer, @virtual_path, @current_template = _old_output_buffer, _old_virtual_path, _old_template
          global_buffer_coordinator&.subscribers&.each { |s| s.output_buffer = _old_output_buffer }
        end
      end

      included do
        attr_accessor :global_buffer_coordinator

        alias_method(:original_output_buffer=, :output_buffer=)
        prepend Compatibility

        alias_method(:original_with_output_buffer, :with_output_buffer)
      end
    end
  end
end
