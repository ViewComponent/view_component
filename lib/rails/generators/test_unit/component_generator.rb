# frozen_string_literal: true

module TestUnit
  module Generators
    class ComponentGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_test_file
        template "component_test.rb", File.join("test/components",  "#{file_name}_test.rb")
      end
    end
  end
end
