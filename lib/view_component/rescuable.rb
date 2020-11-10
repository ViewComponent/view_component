# frozen_string_literal: true

require "active_support/concern"

module ViewComponent
  module Rescuable
    extend ActiveSupport::Concern
    include ActiveSupport::Rescuable

    module ClassMethods
      # Shamelessly copied and adapted from:
      # https://github.com/rails/rails/blob/589dd0f/activesupport/lib/active_support/rescuable.rb#L88
      #
      # The original version returns the exception itself, or nil (if
      # unhandled). This version, instead, returns whatever was returned
      # by the handler (or true, if nothing was returned), or nil if
      # unhandled.
      #
      # Matches an exception to a handler based on the exception class.
      #
      # If no handler matches the exception, check for a handler matching the
      # (optional) exception.cause. If no handler matches the exception or its
      # cause, this returns +nil+, so you can deal with unhandled exceptions.
      # Be sure to re-raise unhandled exceptions if this is what you expect.
      #
      #     begin
      #       …
      #     rescue => exception
      #       rescue_with_handler(exception) || raise
      #     end
      #
      # Returns the handler return value if it was handled and +nil+ if it was not.
      def rescue_with_handler(exception, object: self, visited_exceptions: [])
        visited_exceptions << exception

        if handler = handler_for_rescue(exception, object: object)
          handler.call(exception) || true
        elsif exception
          if visited_exceptions.include?(exception.cause)
            nil
          else
            rescue_with_handler(exception.cause, object: object, visited_exceptions: visited_exceptions)
          end
        end
      end
    end
  end
end
