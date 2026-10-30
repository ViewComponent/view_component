# frozen_string_literal: true

require "generators/view_component/abstract_generator"

module ViewComponent
  module Generators
    class PreviewGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      class_option :preview_path, type: :string, desc: "Path for previews, required when multiple preview paths are configured", default: ViewComponent::Base.config.generate.preview_path

      argument :attributes, type: :array, default: [], banner: "attribute"

      def check_class_collision
        class_collisions "#{component_class_name}Preview"
      end

      def create_preview_file
        preview_paths = ViewComponent::Base.config.previews.paths
        optional_path = options[:preview_path]
        return if preview_paths.count > 1 && optional_path.blank?

        path_prefix = if optional_path.present?
          optional_path
        else
          preview_paths.one? ? preview_paths.first : "test/components/previews"
        end

        template "component_preview.rb", File.join(path_prefix, class_path, "#{destination_file_name}_preview.rb")
      end

      private

      def render_signature
        return if attributes.blank?

        attributes.map { |attr| %(#{attr.name}: "#{attr.name}") }.join(", ")
      end
    end
  end
end
