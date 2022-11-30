# frozen_string_literal: true

module Preview
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "attribute"
      check_class_collision suffix: "ComponentPreview"

      def create_preview_file
        preview_paths = ViewComponent::Base.config.preview_paths
        return if preview_paths.count > 1

        path_prefix = preview_paths.one? ? preview_paths.first : "test/components/previews"
        template "component_preview.rb", File.join(path_prefix, class_path, "#{file_name}_component_preview.rb")
      end

      private

      def file_name
        @_file_name ||= super.sub(/_component\z/i, "")
      end

      def render_signature
        return if attributes.blank?

        attributes.map { |attr| %(#{attr.name}: "#{attr.name}") }.join(", ")
      end
    end
  end
end
