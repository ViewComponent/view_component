# frozen_string_literal: true

require "rails/generators/erb/component_generator"

module Haml
  module Generators
    class ComponentGenerator < Erb::Generators::ComponentGenerator
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)
      class_option :sidecar, type: :boolean, default: false

      def engine_name
        "haml"
      end

      def copy_view_file
        super
      end
    end
  end
end
