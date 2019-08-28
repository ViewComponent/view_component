# frozen_string_literal: true

module ActionView
  module Component
    module TestHelpers
      def render_component(component, **args, &block)
        if component.respond_to?(:render_in)
          ActiveSupport::Deprecation.warn(
            "passing component instances to `render` will be deprecated in actionview-component 2.0. Use `render MyComponent, foo: :bar` instead."
          )

          Nokogiri::HTML(component.render_in(ApplicationController.new.view_context, &block))
        else
          locals = args[:locals] ? args[:locals] : args
          Nokogiri::HTML(component.new(locals).render_in(ApplicationController.new.view_context, &block))
        end
      end
    end
  end
end
