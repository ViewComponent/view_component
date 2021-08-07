# frozen_string_literal: true

module Stimulus
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      class_option :sidecar, type: :boolean, default: false

      def create_stimulus_controller
        template "component_controller.js", destination
      end

      private

      def destination
        if options["sidecar"]
          File.join(component_path, class_path, "#{file_name}_component", "#{file_name}_component_controller.js")
        else
          File.join(component_path, class_path, "#{file_name}_component_controller.js")
        end
      end
    end
  end
end
