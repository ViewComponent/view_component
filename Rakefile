# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rspec/core/rake_task"
require "yard"
require "yard/mattr_accessor_handler"
require "rails/version"
require "simplecov"
require "simplecov-console"

RSpec::Core::RakeTask.new(:spec)

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(:engine_test) do |t|
  t.libs << "test_engine"
  t.libs << "test_engine/lib"
  t.test_files = FileList["test_engine/**/*_test.rb"]
end

desc "Runs benchmarks against components"
task :partial_benchmark do
  ruby "./performance/partial_benchmark.rb"
end

task :translatable_benchmark do
  ruby "./performance/translatable_benchmark.rb"
end

task :slots_benchmark do
  ruby "./performance/slots_benchmark.rb"
end

task :inline_components_benchmark do
  ruby "./performance/inline_benchmark.rb"
end

namespace :coverage do
  task :report do
    require "simplecov"
    require "simplecov-console"

    SimpleCov.minimum_coverage 100

    SimpleCov.collate Dir["{coverage,simplecov-resultset-*}/.resultset.json"], "rails" do
      formatter SimpleCov::Formatter::Console
    end
  end
end

namespace :docs do
  task :build do
    YARD::Rake::YardocTask.new do |t|
      t.options = ["--no-output", "-q"]
    end

    Rake::Task["yard"].execute

    registry = YARD::RegistryStore.new
    registry.load!(".yardoc")

    meths =
      registry
        .get("ViewComponent::Base")
        .meths
        .select do |method|
        !method.tag(:private) &&
          method.path.include?("ViewComponent::Base") &&
          method.visibility == :public &&
          !method[:name].to_s.start_with?("_") # Ignore methods we mark as internal by prefixing with underscores
      end.sort_by { |method| method[:name] }

    instance_methods_to_document = meths.select { |method| method.scope != :class }
    class_methods_to_document = meths.select { |method| method.scope == :class }
    configuration_methods_to_document = registry.get("ViewComponent::Config").meths.select(&:reader?)
    test_helper_methods_to_document = registry
      .get("ViewComponent::TestHelpers")
      .meths
      .sort_by { |method| method[:name] }
      .select do |method|
      !method.tag(:private) &&
        method.visibility == :public
    end

    require "rails"
    require "action_controller"
    require "view_component"
    require "docs/docs_builder_component"

    error_keys = registry.keys.select { |key| key.to_s.include?("Error::MESSAGE") }.map(&:to_s)

    docs = ActionController::Base.renderer.render(
      ViewComponent::DocsBuilderComponent.new(
        sections: [
          ViewComponent::DocsBuilderComponent::Section.new(
            heading: "Class methods",
            methods: class_methods_to_document
          ),
          ViewComponent::DocsBuilderComponent::Section.new(
            heading: "Instance methods",
            methods: instance_methods_to_document
          ),
          ViewComponent::DocsBuilderComponent::Section.new(
            heading: "Configuration",
            methods: configuration_methods_to_document,
            show_types: false
          ),
          ViewComponent::DocsBuilderComponent::Section.new(
            heading: "ViewComponent::TestHelpers",
            methods: test_helper_methods_to_document
          ),
          ViewComponent::DocsBuilderComponent::Section.new(
            heading: "Errors",
            error_klasses: error_keys
          )
        ]
      )
    ).chomp

    if ENV["RAILS_ENV"] != "test"
      File.open("docs/api.md", "w") do |f|
        f.puts(docs)
      end
    end
  end
end

task :all_tests do
  ENV["RAILS_ENV"] = "test"

  if ENV["MEASURE_COVERAGE"]
    SimpleCov.start do
      command_name "rails#{Rails::VERSION::STRING}-ruby#{RUBY_VERSION}"
      enable_coverage :branch
      formatter SimpleCov::Formatter::Console
    end
  end

  puts "Running Minitests"
  Rake::Task["test"].invoke
  puts
  puts
  puts "Running Minitests for Rails Engine compatibility"
  Rake::Task["engine_test"].invoke
  puts
  puts
  puts "Running RSpecs"
  Rake::Task["spec"].invoke
end

task default: [:all_tests]
