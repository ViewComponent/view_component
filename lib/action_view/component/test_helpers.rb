# frozen_string_literal: true

module ActionView
  module Component
    module TestHelpers
      def render_component(component, &block)
        Nokogiri::HTML(component.render_in(ApplicationController.new.view_context, &block))
      end
    end
  end
end
