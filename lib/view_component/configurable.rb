# frozen_string_literal: true

module ViewComponent
  module Configurable
    extend ActiveSupport::Concern

    class_methods do
      def config
        @_config ||= if respond_to?(:superclass) && superclass.respond_to?(:config)
          superclass.config.inheritable_copy
        else
          ActiveSupport::OrderedOptions.new
        end
      end

      def configure
        yield config
      end
    end

    included do
      next if respond_to?(:config) && config.respond_to?(:view_component) && config.respond_to_missing?(:instrumentation_enabled)

      configure do |config|
        config.view_component ||= ActiveSupport::InheritableOptions.new
      end

      def config
        self.class.config
      end
    end
  end
end
