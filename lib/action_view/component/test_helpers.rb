# frozen_string_literal: true

module ActionView
  module Component
    module TestHelpers
      def render_component(options = {}, &block)
        Nokogiri::HTML(options[:component].new(options[:locals]).render_in(ApplicationController.new.view_context, &block))
      end
    end
  end
end
