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

      case string = buffer.presence || value
      when ActionView::OutputBuffer
        string.to_s
      when ActiveSupport::SafeBuffer
        string
      when String
        ERB::Util.html_escape(string)
      end
    end
  end
end
