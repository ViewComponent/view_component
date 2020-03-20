# frozen_string_literal: true

module ViewComponent
  module RenderMonkeyPatch # :nodoc:
    def render(options = {}, args = {}, &block)
      if options.respond_to?(:render_in)
        options.render_in(self, &block)
      else
        super
      end
    end
  end
end
