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
            create_file destination(locale), translations_hash([locale]).to_yaml
          end
        else
          create_file destination, translations_hash(I18n.available_locales.presence).to_yaml
        end
      end

      private

      def translations_hash(locales = [:en])
        locales.to_h { |locale| [locale.to_s, translation_keys] }
      end

      def translation_keys
        keys = attributes.map(&:name).presence || [:hello]
        keys.to_h { |key| [key.to_s, "#{key.capitalize}"] }
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
