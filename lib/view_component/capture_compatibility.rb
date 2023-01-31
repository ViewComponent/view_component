# frozen_string_literal: true

module ViewComponent
  module CaptureCompatibility

    def self.included(base)
      base.class_eval do
        alias_method :original_capture, :capture
      end

      base.prepend(Methods)
    end

    module Methods
      def capture(*args, &block)
        block_context = block.binding.receiver

        if block_context.respond_to?(:render_in) && block_context.respond_to?(:with_output_buffer)
          block_context.original_capture(*args, &block)
        else
          original_capture(*args, &block)
        end
      end
    end
  end
end
