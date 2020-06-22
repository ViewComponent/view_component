# frozen_string_literal: true
require "bundler/gem_tasks"
require "rake/testtask"

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
  system("rake test_render_monkey_patch_enabled RAILS_ENV=test_render_monkey_patch_enabled")
  system("rake test_render_monkey_patch_disabled RAILS_ENV=test_render_monkey_patch_disabled")
end

task default: :test
