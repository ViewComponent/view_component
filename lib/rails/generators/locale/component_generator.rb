# frozen_string_literal: true

require "rails/generators/abstract_generator"

module Locale
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      argument :attributes, type: :array, default: [], banner: "attribute"
      class_option :sidecar, type: :boolean, default: false

      def create_locale_file
        if ViewComponent::Base.generate_splitted_locale_files
          I18n.available_locales.each do |locale|
            @locales = [locale]
            template "component.yml", destination(locale)
          end
        else
          @locales = I18n.available_locales.presence || [:en]
          template "component.yml", destination
        end
      end

      private

      def render_translations
        keys = attributes.map(&:name).presence || [:hello]
        keys.map { |key| %(  #{key}: "#{key.capitalize}") }.join("\n")
      end

      def destination(locale = nil)
        extention = ".#{locale}" if locale
        if options["sidecar"]
          File.join(component_path, class_path, "#{file_name}_component", "#{file_name}_component#{extention}.yml")
        else
          File.join(component_path, class_path, "#{file_name}_component#{extention}.yml")
        end
      end
    end
  end
end
