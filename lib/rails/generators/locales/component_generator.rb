# frozen_string_literal: true

require "rails/generators/abstract_generator"

module Locales
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      class_option :sidecar, type: :boolean, default: false

      def create_locale_file
        I18n.available_locales.each do |locale|
          dest_with_path = destination(locale)
          template "component.yml", dest_with_path
          gsub_file dest_with_path, /\Aen:\n/, "#{locale}:\n"
        end
      end

      private

      def destination(locale)
        if options["sidecar"]
          File.join(component_path, class_path, "#{file_name}_component", "#{file_name}_component.#{locale}.yml")
        else
          File.join(component_path, class_path, "#{file_name}_component.#{locale}.yml")
        end
      end
    end
  end
end
