# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "simplecov"
require "simplecov-erb"

task :simple_cov do
  SimpleCov.start do
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::ERBFormatter,
      SimpleCov::Formatter::HTMLFormatter
])
  end

  SimpleCov.minimum_coverage 98 # TODO: Get to 100!
  SimpleCov.command_name "Unit Tests"
end

Rake::TestTask.new(:test_render_monkey_patch_enabled) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(:test_render_monkey_patch_disabled) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/view_component/render_monkey_patch_disabled_integration_test.rb"]
end


task :test do
  Rake::Task["simple_cov"].invoke
  system("rake test_render_monkey_patch_enabled RAILS_ENV=test_render_monkey_patch_enabled")
  system("rake test_render_monkey_patch_disabled RAILS_ENV=test_render_monkey_patch_disabled")
end

task default: :test
