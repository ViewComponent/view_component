# frozen_string_literal: true

require "rails/generators/abstract_generator"

module Translations
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      class_option :sidecar, type: :boolean, default: false

      def create_translations_file
        template "component.yml", destination
      end

      private

      def destination
        if options["sidecar"]
          File.join(component_path, class_path, "#{file_name}_component", "#{file_name}_component.yml")
        else
          File.join(component_path, class_path, "#{file_name}_component.yml")
        end
      end
    end
  end
end
