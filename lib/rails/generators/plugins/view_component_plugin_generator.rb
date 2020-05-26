# frozen_string_literal: true

require "/rails/generators/rails/plugin/plugin_generator"

module Rails
  module Generators
    class ViewComponentPluginGenerator < Rails::Generators::PluginGenerator
      source_root superclass.source_root

      def self.source_paths
        [source_root, File.expand_path("templates", __dir__)]
      end

      def self.banner
        "view_component engine #{arguments.map(&:usage).join(' ')} [options]"
      end

      def apply_view_component_changes
        # Add App Directory and a sample component
        empty_directory "app/components"
        template "my_component.html.erb", File.join("app/components", namespaced_name, "my_component.html.erb")
        template "my_component.rb", File.join("app/components", namespaced_name, "my_component.rb")

        # Setup lib folder
        template "lib_components.rb", File.join("lib", namespaced_name, "components.rb")
        template "lib_engine.rb", File.join("lib", namespaced_name, "components", "engine.rb")

        # Setup tests
        empty_directory "test/components"
        template "my_component_test.rb", File.join("test/components", "my_component_test.rb")
        inject_into_file "test/test_helper.rb", "require \"view_component/test_helpers\"\n\n", after: "require_relative \"../test/dummy/config/environment\"\n"
        
        # Add components engine to the dummy application
        if with_dummy_app?
          gsub_file "test/dummy/config/application.rb", "require \"my_engine\"", "require \"#{namespaced_name}/components\""
        end

        # Add ourselves to the gemspec
        unless options[:skip_gemspec]
          inject_into_file "#{namespaced_name}.gemspec",
            "\n  spec.add_dependency \"view_component\", \"~> #{ViewComponent::VERSION::STRING}\"",
            after: /#?\s*spec\.add_dependency "rails".*/
        end

        append_file "Gemfile", "\ngem \"capybara\""
      end
    end
  end
end
