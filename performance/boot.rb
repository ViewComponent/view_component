# frozen_string_literal: true

# Boots a production app with eager-loaded components in a fresh process and prints, as JSON,
# the time and allocations spent in ViewComponent (requiring it, loading components, and
# compiling them) and in the rest of boot. Used by performance/measure.rb.
#
#   ruby performance/boot.rb APP_ROOT

start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
start_allocations = GC.stat(:total_allocated_objects)

require "bundler/setup"
require "json"
require "logger"

view_component = {"seconds" => 0.0, "allocations" => 0}
measure = lambda do |&block|
  allocations = GC.stat(:total_allocated_objects)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  block.call
  view_component["seconds"] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  view_component["allocations"] += GC.stat(:total_allocated_objects) - allocations
end

ENV["RAILS_ENV"] = "production"
require "rails"
require "action_controller/railtie"

$LOAD_PATH.unshift(ENV.fetch("VIEW_COMPONENT_LIB"))
measure.call { require "view_component" }

class BootApp < Rails::Application
  config.root = ARGV.fetch(0)
  config.load_defaults Rails::VERSION::STRING.to_f
  config.cache_classes = true
  config.eager_load = true
  config.secret_key_base = "performance"
  config.logger = Logger.new(nil)
end

BootApp.config.before_eager_load do |app|
  measure.call { Rails.autoloaders.main.eager_load_dir(app.root.join("app/components").to_s) }
end

ActiveSupport::Notifications.subscribe("compile.view_component") do |event|
  view_component["seconds"] += event.duration / 1000
  view_component["allocations"] += event.allocations
end

BootApp.initialize!

total_seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
total_allocations = GC.stat(:total_allocated_objects) - start_allocations

puts JSON.generate(
  "view_component" => view_component,
  "rest" => {
    "seconds" => total_seconds - view_component["seconds"],
    "allocations" => total_allocations - view_component["allocations"]
  }
)
