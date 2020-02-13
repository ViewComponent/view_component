# frozen_string_literal: true

require "active_support/concern"

module ActionView
  module Component # :nodoc:
    module NoOpValidations
      extend ActiveSupport::Concern

      included do
        def validate!
        end
      end
    end
  end
end
