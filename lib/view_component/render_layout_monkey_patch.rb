# frozen_string_literal: true

module ViewComponent
  module RenderLayoutMonkeyPatch # :nodoc:
    def render(options = {}, locals = {}, &block)
      if locals[:layout].blank? || locals[:layout].is_a?(Symbol) || locals[:layout].is_a?(String)
        super(options, locals, &block)
      else
        render(locals[:layout]) do
          options.render_in(self, &block)
        end
      end
    end
  end
end





