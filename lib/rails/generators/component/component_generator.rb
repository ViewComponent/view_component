# frozen_string_literal: true

module Rails
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "attribute"
      check_class_collision suffix: "Component"

      class_option :require_content, type: :boolean, default: false

      def create_component_file
        template "component.rb", File.join("app/components", class_path, "#{file_name}_component.rb")
      end

      hook_for :test_framework

      hook_for :template_engine do |instance, template_engine|
        instance.invoke template_engine, [ instance.name ], require_content: instance.send(:requires_content?)
      end

      private

      def file_name
        @_file_name ||= super.sub(/_component\z/i, "")
      end

      def requires_content?
        return if behavior == :revoke
        return @requires_content if @asked

        @asked = true
        @requires_content = ask("Would you like #{class_name} to require content? (Y/n)").downcase == "y"
      end

      def parent_class
        defined?(ApplicationComponent) ? "ApplicationComponent" : "ActionView::Component::Base"
      end

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
