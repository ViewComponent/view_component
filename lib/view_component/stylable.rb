# frozen_string_literal: true

require "active_support/concern"
require "view_component/css_module"

module ViewComponent
  # EXPERIMENTAL
  # Support for CSS Modules. Use at your own peril!
  module Stylable
    extend ActiveSupport::Concern

    class_methods do
      def _after_compile
        return unless css_file_path = _sidecar_files(["css"]).first

        rewrite = ViewComponent::CSSModule.new(
          self.name.demodulize.gsub("Component", ""),
          File.read(css_file_path)
        ).rewrite

        @css = rewrite[:css]
        @styles = rewrite[:mappings]
      end

      def css
        ensure_compiled

        @css
      end

      def styles
        ensure_compiled

        @styles
      end
    end

    def _after_render
      style_tag
    end

    def style_tag
      rendered_components = request.params["___rendered_view_components"] ||= Set.new
      rendered_components_identifier = "#{Rails.application.class.name}::#{self.class.name}"

      # Only render the component's style tag once per request
      if !rendered_components.include?(rendered_components_identifier)
        request.params["___rendered_view_components"] << rendered_components_identifier

        content_tag(:style, self.class.css.html_safe) # rubocop:disable Rails/OutputSafety
      end
    end

    def styles
      self.class.styles
    end
  end
end