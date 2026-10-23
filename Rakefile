# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rspec/core/rake_task"
require "yard"
require "yard/mattr_accessor_handler"
require "rails/version"
require "tmpdir"
require "simplecov"
require "simplecov-console"

RSpec::Core::RakeTask.new(:spec)

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/isolated/**/*")
end

# Each test boots its own application, so these can't share a process with the sandbox.
Rake::TestTask.new(:isolated_test) do |t|
  t.libs << "lib"
  t.test_files = FileList["test/isolated/**/*_test.rb"]
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

desc "Verify the app boots with eager_load=true (catches missing requires)"
task :eager_load_check do
  puts "Checking eager loading..."
  # Boot a minimal Rails app with eager_load enabled. Using a bare app (no
  # components) ensures Zeitwerk doesn't accidentally autoload
  # ViewComponent::Base before processing the engine's controllers — exactly
  # the scenario that triggers NameError in a fresh host application.
  result = system(
    {"RAILS_ENV" => "test"},
    "bundle", "exec", "ruby", "-e", <<~RUBY
      require "rails"
      require "action_controller/railtie"
      require "view_component"

      class EagerLoadCheckApp < Rails::Application
        config.eager_load = true
        config.secret_key_base = "test"
        config.hosts.clear
      end

      EagerLoadCheckApp.initialize!
    RUBY
  )
  abort("Eager loading check failed!") unless result
  puts "Eager loading check passed"
end

# Gems that are used, but not loaded by `rake all_tests`.
GEMS_NOT_LOADED_BY_TESTS = %w[
  appraisal appraisal-run audition erb_lint m rubocop-md standard yard-lint
  benchmark-ips
  bundler rails
  propshaft puma sprockets-rails
].freeze

desc "Fail if a gem in the Gemfile or gemspec wasn't loaded by the test suite"
task :unused_gems_check do
  loaded = Dir[File.join(ENV.fetch("LOADED_GEMS_DIR"), "*.txt")].flat_map { File.readlines(_1, chomp: true) }
  loaded |= Gem.loaded_specs.values.select { |spec| $LOADED_FEATURES.any? { _1.start_with?("#{spec.full_gem_path}/") } }.map(&:name)

  declared = Bundler.definition.dependencies.map(&:name) - ["view_component"]
  declared |= Gem::Specification.load("view_component.gemspec").runtime_dependencies.map(&:name)

  unused = declared - loaded - GEMS_NOT_LOADED_BY_TESTS
  abort("Gems not loaded by the test suite, remove them or add them to GEMS_NOT_LOADED_BY_TESTS: #{unused.sort.join(", ")}") if unused.any?
  puts "Unused gems check passed"
end

task :all_tests do
  ENV["RAILS_ENV"] = "test"
  ENV["LOADED_GEMS_DIR"] = Dir.mktmpdir
  ENV["RUBYOPT"] = "#{ENV["RUBYOPT"]} -r#{File.expand_path("script/record_loaded_gems.rb", __dir__)}"

  if ENV["MEASURE_COVERAGE"]
    SimpleCov.start do
      command_name "rails#{Rails::VERSION::STRING}-ruby#{RUBY_VERSION}"
      enable_coverage :branch
      formatter SimpleCov::Formatter::Console
    end
  end

  puts "Checking eager loading"
  Rake::Task["eager_load_check"].invoke
  puts
  puts
  puts "Running Minitests"
  Rake::Task["test"].invoke
  puts
  puts
  puts "Running isolated Minitests"
  Rake::Task["isolated_test"].invoke
  puts
  puts
  puts "Running Minitests for Rails Engine compatibility"
  Rake::Task["engine_test"].invoke
  puts
  puts
  puts "Running RSpecs"
  Rake::Task["spec"].invoke
  puts
  puts
  Rake::Task["unused_gems_check"].invoke
end

task default: [:all_tests]
