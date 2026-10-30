# frozen_string_literal: true

require "generators/view_component/abstract_generator"

module ViewComponent
  module Generators
    class StimulusGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      class_option :sidecar, type: :boolean
      class_option :typescript, type: :boolean

      def create_stimulus_controller
        template "component_controller.#{filetype}", destination
      end

      def stimulus_module
        return "stimulus" if legacy_stimulus?

        "@hotwired/stimulus"
      end

      private

      def filetype
        typescript? ? "ts" : "js"
      end

      def destination
        File.join(destination_directory, "#{destination_file_name}_controller.#{filetype}")
      end

      def legacy_stimulus?
        package_json_pathname = Rails.root.join("package.json")
        package_json_pathname.exist? && JSON.parse(package_json_pathname.read).dig("dependencies", "stimulus").present?
      end
    end
  end
end
