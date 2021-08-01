# frozen_string_literal: true

module Stimulus
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)

      def create_stimulus_controller
        template "component_controller.js", File.join(component_path, class_path, "#{file_name}_component_controller.js")
      end
    end
  end
end
