# frozen_string_literal: true

# Measures executor-only work on four threads, like Action Cable's worker pool.
# Used by performance/measure.rb with and without ViewComponent in fresh processes.
#
#   ruby performance/executor.rb APP_ROOT [reference]

require "bundler/setup"
require "json"
require "logger"

ENV["RAILS_ENV"] = "development"
require "rails"
require "action_controller/railtie"
unless ARGV[1] == "reference"
  $LOAD_PATH.unshift(ENV.fetch("VIEW_COMPONENT_LIB"))
  require "view_component"
end

class ExecutorApp < Rails::Application
  config.root = ARGV.fetch(0)
  config.load_defaults Rails::VERSION::STRING.to_f
  config.enable_reloading = true
  config.eager_load = false
  config.action_view.cache_template_loading = false
  config.file_watcher = ActiveSupport::FileUpdateChecker
  config.secret_key_base = "performance"
  config.logger = Logger.new(nil)
end
ExecutorApp.initialize!
raise "templates must not be cached" if ActionView::Base.cache_template_loading

clock = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
measure = lambda do |iterations|
  GC.start
  allocations = GC.stat(:total_allocated_objects)
  start = clock.call
  Array.new(4) do
    Thread.new { iterations.times { ExecutorApp.executor.wrap {} } }
  end.each(&:value)
  {
    "seconds" => (clock.call - start) / (iterations * 4),
    "allocations" => (GC.stat(:total_allocated_objects) - allocations).fdiv(iterations * 4)
  }
end

sample_seconds = Float(ENV.fetch("SAMPLE_SECONDS", 0.1))
iterations = 1
iterations *= 2 while measure.call(iterations)["seconds"] * iterations * 4 < sample_seconds / 4
iterations *= 4

puts JSON.generate(
  "iterations" => iterations * 4,
  "samples" => Array.new(Integer(ENV.fetch("PASSES", 15))) { measure.call(iterations) }
)
