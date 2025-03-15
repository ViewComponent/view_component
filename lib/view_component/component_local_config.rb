# frozen_string_literal: true

module ViewComponent
  module ComponentLocalConfig
    class Configuration
      def initialize
        @config = ActiveSupport::OrderedOptions[
          strip_trailing_whitespace: false
        ]
      end

      delegate_missing_to :@config

      def inheritable_copy
        new.instance_variable_set(:@config, @config.inheritable_copy)
      end
    end

    extend ActiveSupport::Concern

    included do
      def configuration
        @_configuration ||= self.class.configuration.inheritable_copy
      end

      private

      def inherited(child)
        child.instance_variable_set(:@_configuration, nil)
        super
      end
    end

    class_methods do
      def configuration
        @_configuration ||= if respond_to?(:superclass) && superclass.respond_to?(:configuration)
          superclass.configuration.inheritable_copy
        else
          # create a new "anonymous" class that will host the compiled reader methods
          Class.new(ActiveSupport::Configurable::Configuration).new
        end
      end

      def configure(&block)
        configuration.instance_eval(&block)
        configuration.compile_methods!
      end
    end
  end
end
