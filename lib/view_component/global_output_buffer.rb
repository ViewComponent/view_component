# frozen_string_literal: true

module ViewComponent
  module GlobalOutputBuffer
    def render_in(view_context, &block)
      unless view_context.output_buffer.is_a?(OutputBufferStack)
        # use instance_variable_set here to avoid triggering the code in the #output_buffer= method below
        view_context.instance_variable_set(:@output_buffer, OutputBufferStack.new(view_context.output_buffer))
      end

      @output_buffer = view_context.output_buffer
      @global_buffer_in_use = true

      super(view_context, &block)
    end

    def perform_render
      # HAML unhelpfully assigns to @output_buffer directly, so we hold onto a reference to
      # it and restore @output_buffer when the HAML engine is finished. In non-HAML cases,
      # @output_buffer and orig_buf will point to the same object, making the reassignment
      # statements no-ops.
      orig_buf = @output_buffer
      @output_buffer.push
      result = render_template_for(@__vc_variant).to_s + _output_postamble
      @output_buffer = orig_buf
      @output_buffer.pop
      result
    end

    def output_buffer=(other_buffer)
      @output_buffer.replace(other_buffer)
    end

    def with_output_buffer(buf = nil)
      unless buf
        buf = ActionView::OutputBuffer.new
        if output_buffer && output_buffer.respond_to?(:encoding)
          buf.force_encoding(output_buffer.encoding)
        end
      end

      output_buffer.push(buf)
      result = nil

      begin
        yield
      ensure
        # assign result here to avoid a return statement, which will
        # immediately return to the caller and swallow any errors
        result = output_buffer.pop
      end

      result
    end

    module ActionViewMods
      def output_buffer=(other_buffer)
        if @output_buffer.is_a?(OutputBufferStack)
          @output_buffer.replace(other_buffer)
        else
          super
        end
      end

      def with_output_buffer(buf = nil)
        unless buf
          buf = ActionView::OutputBuffer.new
          if @output_buffer && @output_buffer.respond_to?(:encoding)
            buf.force_encoding(@output_buffer.encoding)
          end
        end

        result = nil

        if @output_buffer.is_a?(OutputBufferStack)
          @output_buffer.push(buf)

          begin
            yield
          ensure
            result = @output_buffer.pop
          end

          result
        else
          @output_buffer, old_buffer = buf, output_buffer

          begin
            yield
          ensure
            @output_buffer = old_buffer
          end

          buf
        end
      end
    end
  end
end
