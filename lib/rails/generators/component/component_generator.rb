# frozen_string_literal: true

module Rails
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

      def requires_content?
        return @requires_content if @asked

        @asked = true
        @requires_content = ask("Would you like #{class_name} to require content? (Y/n)").downcase == "y"
      end

      def parent_class
        defined?(ApplicationComponent) ? "ApplicationComponent" : "ActionView::Component::Base"
      end

      def initialize_signature
        if attributes.present?
          attributes.map(&:name).join(":, ")
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
