# frozen_string_literal: true

module ViewComponent
  module ActionViewCompatibility
    extend ActiveSupport::Concern

    def form_for(*args, **kwags, &block)
      with_compatible_capture do
        super
      end
    end

    def form_with(*args, **kwargs, &block)
      with_compatible_capture do
        super
      end
    end

    included do
      alias_method :original_capture, :capture
      alias_method :capture, :capture_with_compatibility
    end

    def with_compatible_capture(&block)
      old_compatible_capture = defined?(@compatible_capture) ? @compatible_capture : false
      @compatible_capture = true
      yield
    ensure
      @compatible_capture = old_compatible_capture
    end

    def capture_with_compatibility(*args, &block)
      if defined?(@compatible_capture) && @compatible_capture
        receiver_aware_capture(*args, &block)
      else
        original_capture(*args, &block)
      end
    end

    def receiver_aware_capture(*args, &block)
      receiver = block.binding.receiver

      if receiver != self && receiver.respond_to?(:output_buffer=)
        if receiver.respond_to?(:original_capture)
          receiver.original_capture(*args, &block)
        else
          receiver.capture(*args, &block)
        end
      else
        original_capture(*args, &block)
      end
    end
  end
end
