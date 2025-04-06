# frozen_string_literal: true

module ViewComponent
  module ComponentLocalConfig
    class Configuration
      def self.defaults
        ActiveSupport::Configurable::Configuration[
          strip_trailing_whitespace: false
        ]
      end

      def initialize(config = defaults)
        @config = config
      end

      delegate_missing_to :@config

      def inheritable_copy
        self.class.new(@config.inheritable_copy)
      end

      private

      delegate :defaults, to: :class
    end

    extend ActiveSupport::Concern

    included do
      # :nocov:
      def view_component_config
        @__vc_config ||= self.class.view_component_config.inheritable_copy
      end

      private

      def inherited(child)
        child.instance_variable_set(:@__vc_config, nil)
        super
      end
      # :nocov:
    end

    class_methods do
      def view_component_config
        @__vc_config ||= if respond_to?(:superclass) && superclass.respond_to?(:view_component_config)
          superclass.view_component_config.inheritable_copy
        else
          # create a new "anonymous" class that will host the compiled reader methods
          ViewComponent::ComponentLocalConfig::Configuration.new
        end
      end

      def configure_view_component(&block)
        view_component_config.instance_eval(&block)
        view_component_config.compile_methods!
      end
    end
  end
end
