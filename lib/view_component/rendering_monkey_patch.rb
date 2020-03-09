# frozen_string_literal: true

module ViewComponent
  module RenderingMonkeyPatch # :nodoc:
    def render(options = {}, args = {})
      if options.respond_to?(:render_in) && Rails.version.to_f < 6.1
        self.response_body = options.render_in(self.view_context)
      else
        super
      end
    end
  end
end
