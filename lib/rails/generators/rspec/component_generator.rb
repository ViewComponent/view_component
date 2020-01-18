# frozen_string_literal: true

module Rspec
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_test_file
        template "component_spec.rb", File.join("spec/components", class_path, "#{file_name}_component_spec.rb")
      end

      private

      def file_name
        @_file_name ||= super.sub(/_component\z/i, "")
      end
    end
  end
end
