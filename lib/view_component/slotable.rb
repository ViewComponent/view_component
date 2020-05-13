# frozen_string_literal: true

require "active_support/concern"

module ViewComponent # :nodoc:
  module Slotable
    extend ActiveSupport::Concern

    included do
      attr_accessor :content
    end

    class_methods do
      def inherited(child)
        # .parent is removed in 6.1,
        # but .module_parent does not exist in 5.0/5.2
        # So this conditional lets us support both <3
        if child.respond_to?(:module_parent)
          child.module_parent.register_slot(child)
        else
          child.parent.register_slot(child)
        end
      end
    end
  end
end
