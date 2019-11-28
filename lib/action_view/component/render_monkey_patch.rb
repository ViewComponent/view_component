# frozen_string_literal: true

# Monkey patch ActionView::Base#render to support ActionView::Component
#
# A version of this monkey patch was upstreamed in https://github.com/rails/rails/pull/36388
# We'll need to upstream an updated version of this eventually.
module ActionView
  module Component
    module RenderMonkeyPatch # :nodoc:
      def render(options = {}, args = {}, &block)
        if options.respond_to?(:render_in)
          ActiveSupport::Deprecation.warn(
            "passing component instances (`render MyComponent.new(foo: :bar)`) has been deprecated and will be removed in v2.0.0. Use `render MyComponent, foo: :bar` instead."
          )

          options.render_in(self, &block)
        elsif options.is_a?(Class) && options < ActionView::Component::Base
          options.new(args).render_in(self, &block)
        elsif options.is_a?(Hash) && options.has_key?(:component)
          options[:component].new(options[:locals]).render_in(self, &block)
        elsif options.respond_to?(:to_component_class) && !options.to_component_class.nil?
          options.to_component_class.new(options).render_in(self, &block)
        else
          super
        end
      end
    end
  end
end
