# frozen_string_literal: true

require "rails/generators/erb/component_generator"

module Slim
  module Generators
    class ComponentGenerator < Erb::Generators::ComponentGenerator
      source_root File.expand_path("templates", __dir__)

      def copy_view_file
        template "component.html.slim", File.join("app/components", class_path, "#{file_name}_component.html.slim")
      end

      private

      def file_name
        @_file_name ||= super.sub(/_component\z/i, "")
      end
    end
  end
end
