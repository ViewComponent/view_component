# frozen_string_literal: true

module ViewComponent
  # CaptureCompatibility is a module that patches #capture to fix issues
  # related to ViewComponent and functionality that relies on `capture`
  # like forms, capture itself, turbo frames, etc.
  #
  # This underlying incompatibility with ViewComponent and capture is
  # that several features like forms keep a reference to the primary
  # `ActionView::Base` instance which has its own @output_buffer. When
  # `#capture` is called on the original `ActionView::Base` instance while
  # evaluating a block from a ViewComponent the @output_buffer is overridden
  # in the ActionView::Base instance, and *not* the component. This results
  # in a double render due to `#capture` implementation details.
  #
  # To resolve the issue, we override `#capture` so that we can delegate
  # the `capture` logic to the ViewComponent that created the block.
  module CaptureCompatibility
    def self.included(base)
      return if base < InstanceMethods

      base.class_eval do
        alias_method :original_capture, :capture
      end

      base.prepend(InstanceMethods)
    end

    module InstanceMethods
      def capture(*args, &block)
        # Handle blocks that originate from C code and raise, such as `&:method`
        return original_capture(*args, &block) if block.source_location.nil?

        block_context = block.binding.receiver

        if block_context != self && block_context.class < ActionView::Base
          block_context.original_capture(*args, &block)
        else
          original_capture(*args, &block)
        end
      end
    end
  end
end
