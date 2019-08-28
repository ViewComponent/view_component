# frozen_string_literal: true

module ActionView
  module Component
    module TestHelpers
      def render_inline(component, **args, &block)
        Nokogiri::HTML(ApplicationController.new.view_context.render(component, args, &block))
      end
    end
  end
end
