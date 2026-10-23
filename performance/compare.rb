#!/usr/bin/env ruby
# frozen_string_literal: true

# Compares performance/measure.rb runs and fails when any scenario's
# component/partial ratio regresses by more than THRESHOLD (default 0.05).
#
#   ruby performance/compare.rb base.json head.json
#   ruby performance/compare.rb base/ head/
#
# Given directories, it pools the passes from every JSON file in each, since
# timings vary more between processes than between passes in one process.

require "json"

abort "Usage: ruby performance/compare.rb BASE HEAD" unless ARGV.size == 2

median = ->(values) { values.sort[values.size / 2] }
base, head = ARGV.map do |path|
  runs = (File.directory?(path) ? Dir[File.join(path, "*.json")].sort : [path]).map { |file| JSON.parse(File.read(file)) }
  abort "No runs found in #{path}" if runs.empty?

  runs.first.merge(
    "scenarios" => runs.first["scenarios"].to_h do |name, scenario|
      ratios = runs.flat_map { |run| run.dig("scenarios", name, "ratios") || [] }
      [name, scenario.merge("ratio" => median.call(ratios), "ratios" => ratios)]
    end
  )
end
threshold = Float(ENV.fetch("THRESHOLD", 0.05))

puts "### ViewComponent performance (Rails #{head["rails"]}, #{head["ruby"].split.first(2).join(" ")})"
puts
puts "Ratios are component render time / equivalent partial render time, and for `boot`, time spent in ViewComponent during boot / the rest of boot. Lower is faster."
puts
puts "| Scenario | Base ratio | Head ratio | Change | Allocations (base → head) | |"
puts "| --- | ---: | ---: | ---: | ---: | --- |"

regressions = head["scenarios"].filter_map do |name, current|
  previous = base["scenarios"][name]
  unless previous
    puts "| #{name} | — | #{format("%.3f", current["ratio"])} | new | #{current["component_allocations"]} | |"
    next
  end

  change = current["ratio"] / previous["ratio"] - 1
  regressed = current["ratio"] > previous["ratio"] * (1 + threshold)
  puts format(
    "| %s | %.3f | %.3f | %+.1f%% | %d → %d | %s |",
    name, previous["ratio"], current["ratio"], change * 100,
    previous["component_allocations"], current["component_allocations"],
    regressed ? "❌" : "✅"
  )
  name if regressed
end

puts
if regressions.empty?
  puts "No scenario regressed by more than #{(threshold * 100).round(1)}%."
else
  puts "Regressed by more than #{(threshold * 100).round(1)}%: #{regressions.join(", ")}."
  exit 1
end
