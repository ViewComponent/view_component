# frozen_string_literal: true

module ActionView
  module Component
    module TestHelpers
      def render_component(component, **args, &block)
        if component.respond_to?(:render_in)
          Nokogiri::HTML(component.render_in(ApplicationController.new.view_context, &block))
        else
          Nokogiri::HTML(component.new(args[:locals]).render_in(ApplicationController.new.view_context, &block))
        end
      end
    end
  end
end
