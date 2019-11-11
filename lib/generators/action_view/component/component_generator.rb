# frozen_string_literal: true

module ActionView
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "attribute"
      hook_for :test_framework

      def create_component_file
        template "component.rb", File.join("app/components",  "#{file_name}.rb")
      end

      def create_template_file
        template "component.html.erb", File.join("app/components",  "#{file_name}.html.erb")
      end

      private

      def initialize_signature
        if attributes.present?
          attributes.map { |attr| "#{attr.name}:" }.join(", ")
        else
          "*"
        end
      end

      def initialize_body
        attributes.map { |attr| "@#{attr.name} = #{attr.name}" }.join("\n    ")
      end
    end
  end
end
