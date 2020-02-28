# frozen_string_literal: true

module ActionView
  module Component
    module RenderingMonkeyPatch # :nodoc:
      def render(options = {}, args = {}, &block)
        if options.respond_to?(:render_in)
          self.response_body = options.render_in(self.view_context, &block)
        else
          super
        end
      end
    end
  end
end
