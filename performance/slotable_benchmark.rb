# frozen_string_literal: true

# Run `bundle exec rake benchmark` to execute benchmark.
# This is very much a work-in-progress. Please feel free to make/suggest improvements!

require "benchmark/ips"

# Configure Rails Environment
ENV["RAILS_ENV"] = "production"
require File.expand_path("../test/sandbox/config/environment.rb", __dir__)

module Performance
  require_relative "components/slot_component"
  require_relative "components/slots_v2_component"
end

class BenchmarksController < ActionController::Base
end

BenchmarksController.view_paths = [File.expand_path("./views", __dir__)]
controller_view = BenchmarksController.new.view_context

Benchmark.ips do |x|
  x.time = 10
  x.warmup = 2

  x.report("slot:") do
    component = Performance::SlotComponent.new(name: "Fox Mulder")

    controller_view.render(component) do |c|
      c.slot(:header, classes: "my-header") do
        "Hello world"
      end

      c.slot(:item, classes: "a") do
        "First item"
      end

      c.slot(:item, classes: "b") do
        "Second item"
      end
    end
  end
  x.report("subcomponent:") do
    component = Performance::SlotsV2Component.new(name: "Fox Mulder")

    controller_view.render(component) do |c|
      c.header(classes: "my-header") do
        "Hello world"
      end

      c.item(classes: "a") do
        "First item"
      end

      c.item(classes: "b") do
        "Second item"
      end
    end
  end

  x.compare!
end
