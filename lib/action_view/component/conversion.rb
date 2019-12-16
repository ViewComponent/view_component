# frozen_string_literal: true

module ActionView
  module Component # :nodoc:
    module Conversion
      def to_component_class
        "#{self.class.name}Component".safe_constantize
      end
    end
  end
end
