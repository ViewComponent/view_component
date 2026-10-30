# frozen_string_literal: true

require "generators/view_component/abstract_generator"

module ViewComponent
  module Generators
    class TestUnitGenerator < ::Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)

      def check_class_collision
        class_collisions "#{component_class_name}Test"
      end

      def create_test_file
        template "component_test.rb", File.join("test/components", class_path, "#{destination_file_name}_test.rb")
      end
    end
  end
end
