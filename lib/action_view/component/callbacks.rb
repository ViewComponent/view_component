# frozen_string_literal: true

require "active_support/concern"
require "active_support/callbacks"

module ActionView
  module Component
    module Callbacks
      extend ActiveSupport::Concern
      include ActiveSupport::Callbacks

      included do
        define_callbacks :render, terminator: ->(component_instance, result_lambda) do
          result_lambda.call
          component_instance.render_performed?
        end
      end

      module ClassMethods
        def before_render(*filters, &block)
          set_callback(:render, :before, *filters, &block)
        end

        def after_render(*filters, &block)
          set_callback(:render, :after, *filters, &block)
        end

        def around_render(*filters, &block)
          set_callback(:render, :around, *filters, &block)
        end
      end
    end
  end
end
