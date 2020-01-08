# frozen_string_literal: true

module ActionView
  module Component
    class TemplateError < StandardError
      def initialize(errors)
        super(errors.join(", "))
      end
    end
  end
end
