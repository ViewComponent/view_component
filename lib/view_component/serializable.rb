# frozen_string_literal: true

require "active_support/concern"

module ViewComponent
  module Serializable
    extend ActiveSupport::Concern

    included do
      attr_reader :serializable_kwargs
    end

    class_methods do
      def serializable(**kwargs)
        new(**kwargs).tap do |instance|
          instance.instance_variable_set(:@serializable_kwargs, kwargs)
        end
      end
    end
  end
end
