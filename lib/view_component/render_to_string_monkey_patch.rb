# frozen_string_literal: true

module ViewComponent
  module RenderToStringMonkeyPatch # :nodoc:
    def render_to_string(options = {}, args = {})
      if options.respond_to?(:render_in)
        options.render_in(view_context)
      else
        super
      end
    end
  end
end
