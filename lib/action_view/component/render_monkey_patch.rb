# frozen_string_literal: true

# Monkey patch ActionView::Base#render to support ActionView::Component
module ActionView
  module Component
    module RenderMonkeyPatch # :nodoc:
      def render(options = {}, args = {}, &block)
        if options.respond_to?(:render_in)
          options.render_in(self, &block)
        elsif options.is_a?(Class) && options < ActionView::Component::Base
          ActiveSupport::Deprecation.warn(
            "`render MyComponent, foo: :bar` has been deprecated and will be removed in v2.0.0. Use `render MyComponent.new(foo: :bar)` instead."
          )

          options.new(args).render_in(self, &block)
        elsif options.is_a?(Hash) && options.has_key?(:component)
          ActiveSupport::Deprecation.warn(
            "`render component: MyComponent, locals: { foo: :bar }` has been deprecated and will be removed in v2.0.0. Use `render MyComponent.new(foo: :bar)` instead."
          )

          options[:component].new(options[:locals]).render_in(self, &block)
        elsif options.respond_to?(:to_component_class) && !options.to_component_class.nil?
          ActiveSupport::Deprecation.warn(
            "rendering objects that respond_to `to_component_class` has been deprecated and will be removed in v2.0.0. Use `render MyComponent.new(foo: :bar)` instead."
          )

          options.to_component_class.new(options).render_in(self, &block)
        else
          super
        end
      end
    end
  end
end
