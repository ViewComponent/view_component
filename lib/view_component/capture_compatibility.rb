# frozen_string_literal: true

module ViewComponent
  module CaptureCompatibility
    def capture(*args, &block)
      value = nil
      block_context = block.binding.receiver

      buffer = if block_context.respond_to?(:render_in) && block_context.respond_to?(:with_output_buffer)
        block_context.with_output_buffer { value = yield(*args) }
      else
        with_output_buffer { value = yield(*args) }
      end

      if (string = buffer.presence || value) && string.is_a?(String)
        ERB::Util.html_escape string
      end
    end
  end
end
