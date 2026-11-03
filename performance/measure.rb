#!/usr/bin/env ruby
# frozen_string_literal: true

# Measures rendering and cold cache digests relative to ActionView partials,
# and time spent in ViewComponent during app boot relative to the rest of boot.
#
#   bundle exec ruby performance/measure.rb [OUTPUT_JSON]
#
# Set VIEW_COMPONENT_LIB to the `lib` directory of another checkout to measure
# that version of ViewComponent with this checkout's dependencies and scenarios.
# PASSES (default 15), SAMPLE_SECONDS (default 0.1), and BOOT_COMPONENTS
# (default 300) tune the run length.

require "bundler/setup"
require "fileutils"
require "json"
require "logger"
require "tmpdir"

view_component_lib = File.expand_path(ENV.fetch("VIEW_COMPONENT_LIB") { File.expand_path("../lib", __dir__) })
$LOAD_PATH.unshift(view_component_lib)

ENV["RAILS_ENV"] = "production"
require "rails"
require "action_controller/railtie"
require "slim"
require "view_component"

class PerformanceApp < Rails::Application
  # Without an explicit root, Rails would prepend this checkout's lib to $LOAD_PATH.
  config.root = __dir__
  config.load_defaults Rails::VERSION::STRING.to_f
  config.eager_load = false
  config.secret_key_base = "performance"
  config.logger = Logger.new(nil)
end
PerformanceApp.initialize!

module Performance
  require_relative "components/name_component"
  require_relative "components/nested_name_component"
  require_relative "components/inline_component"
  require_relative "components/new_inline_component"
  require_relative "components/slots_component"
  require_relative "components/slots_wrapper_component"
end

class BenchmarksController < ActionController::Base
end
BenchmarksController.view_paths = [File.expand_path("views", __dir__)]
view = BenchmarksController.new.view_context

NAME = "Fox Mulder"
NAMES = Array.new(50, NAME)

reference = proc { view.render("partial", name: NAME) }
scenarios = {
  "component" => proc { view.render(Performance::NameComponent.new(name: NAME)) },
  "inline_call" => proc { view.render(Performance::InlineComponent.new(name: NAME)) },
  "inline_erb_template" => proc { view.render(Performance::NewInlineComponent.new(name: NAME)) },
  "slots" => proc { view.render(Performance::SlotsWrapperComponent.new) },
  "collection" => proc { view.render(Performance::NestedNameComponent.with_collection(NAMES)) }
}

passes = Integer(ENV.fetch("PASSES", 15))
sample_seconds = Float(ENV.fetch("SAMPLE_SECONDS", 0.1))

clock = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
time = lambda do |block, iterations|
  GC.start
  start = clock.call
  iterations.times(&block)
  (clock.call - start) / iterations
end
allocations = lambda do |block|
  block.call
  before = GC.stat(:total_allocated_objects)
  block.call
  GC.stat(:total_allocated_objects) - before
end
iterations_for = lambda do |block|
  iterations = 1
  iterations *= 2 while time.call(block, iterations) * iterations < sample_seconds / 4
  iterations * 4
end
median = ->(values) { values.sort[values.size / 2] }

measure = lambda do |name, reference, scenario|
  [reference, scenario].each { |block| 3.times(&block) }
  reference_iterations = iterations_for.call(reference)
  scenario_iterations = iterations_for.call(scenario)

  samples = Array.new(passes) do |pass|
    if pass.even?
      reference_time = time.call(reference, reference_iterations)
      scenario_time = time.call(scenario, scenario_iterations)
    else
      scenario_time = time.call(scenario, scenario_iterations)
      reference_time = time.call(reference, reference_iterations)
    end
    [reference_time, scenario_time]
  end

  ratios = samples.map { |reference_time, scenario_time| scenario_time / reference_time }
  ratio = median.call(ratios)
  result = {
    "ratio" => ratio,
    "ratios" => ratios,
    "iterations" => {"reference" => reference_iterations, "component" => scenario_iterations},
    "reference_ms" => median.call(samples.map(&:first)) * 1000,
    "component_ms" => median.call(samples.map(&:last)) * 1000,
    "reference_allocations" => allocations.call(reference),
    "component_allocations" => allocations.call(scenario)
  }
  puts format("%-20s ratio %.3f  component %.3fms  partial %.3fms", name, ratio, result["component_ms"], result["reference_ms"])
  result
end

results = scenarios.to_h { |name, scenario| [name, measure.call(name, reference, scenario)] }

# Cold digests and boot share a generated app with overlapping dependencies.
Dir.mktmpdir do |root|
  components = File.join(root, "app", "components")
  FileUtils.mkdir_p(components)

  # Each component renders another, so boot also discovers cache digest dependencies.
  # Every component has a Slim counterpart, so non-ERB templates are covered too.
  render_call = lambda do |i|
    case i % 3
    when 0 then "render Sidecar#{i}Component.new(name: 'x')"
    when 1 then "render(Inline#{i}Component.new) { 'x' }"
    else "render Slots#{i}Component.new"
    end
  end

  component_count = Integer(ENV.fetch("BOOT_COMPONENTS", 300))
  raise "BOOT_COMPONENTS must be at least 2" if component_count < 2

  # A helper included by every component makes dependencies converge and form
  # cycles, rather than only following the mostly tree-shaped template renders.
  shared_components = (([component_count - 6, 0].max)...component_count).to_a
  shared_renders = shared_components.flat_map do |i|
    [render_call.call(i), "render Slim#{i}Component.new(name: 'x')"]
  end
  File.write(File.join(components, "shared_component_helpers.rb"), <<~RUBY)
    module SharedComponentHelpers
      def shared_components
    #{shared_renders.map { |render| "    #{render}" }.join("\n")}
      end
    end
  RUBY

  component_count.times do |i|
    rendered = render_call.call(i.zero? ? 1 : (i - 1) / 2)
    case i % 3
    when 0
      File.write(File.join(components, "sidecar#{i}_component.rb"), <<~RUBY)
        class Sidecar#{i}Component < ViewComponent::Base
          include SharedComponentHelpers

          def initialize(name:)
            @name = name
          end
        end
      RUBY
      File.write(File.join(components, "sidecar#{i}_component.html.erb"), "<p><%= @name %></p><%= #{rendered} %>\n")
    when 1
      File.write(File.join(components, "inline#{i}_component.rb"), <<~RUBY)
        class Inline#{i}Component < ViewComponent::Base
          include SharedComponentHelpers

          erb_template "<p><%= content %></p><%= #{rendered} %>"
        end
      RUBY
    else
      File.write(File.join(components, "slots#{i}_component.rb"), <<~RUBY)
        class Slots#{i}Component < ViewComponent::Base
          include SharedComponentHelpers

          renders_one :header
          renders_many :items
        end
      RUBY
      File.write(File.join(components, "slots#{i}_component.html.erb"), "<%= header %><% items.each do |item| %><%= item %><% end %><%= #{rendered} %>\n")
    end

    File.write(File.join(components, "slim#{i}_component.rb"), <<~RUBY)
      class Slim#{i}Component < ViewComponent::Base
        include SharedComponentHelpers

        def initialize(name:)
          @name = name
        end
      end
    RUBY
    File.write(File.join(components, "slim#{i}_component.html.slim"), "p = @name\n== render Slim#{i.zero? ? 1 : (i - 1) / 2}Component.new(name: 'x')\n")
  end

  require File.join(components, "shared_component_helpers")
  Dir[File.join(components, "*_component.rb")].sort.each { |file| require file }

  # New lookup contexts are essential: existing contexts retain their digest
  # caches even after DetailsKey.clear. Do not warm synthetic sources at boot.
  cold_digest = lambda do |&block|
    ActionView::LookupContext::DetailsKey.clear
    finder = ActionView::LookupContext.new(BenchmarksController.view_paths, formats: [:html])
    block.call(finder)
  end
  digest_reference = proc do
    cold_digest.call { |finder| ActionView::Digestor.digest(name: "benchmarks/_partial", finder: finder) }
  end
  digest_scenario = proc do
    cold_digest.call { |finder| Sidecar0Component.cache_digest(finder: finder) }
  end
  results["cold_digest"] = measure.call("cold_digest", digest_reference, digest_scenario)

  boot = lambda do
    output = IO.popen({"VIEW_COMPONENT_LIB" => view_component_lib}, [RbConfig.ruby, File.expand_path("boot.rb", __dir__), root], &:read)
    raise "boot failed" unless $?.success?
    JSON.parse(output)
  end

  boot.call
  samples = Array.new(passes) { boot.call }
  ratios = samples.map { |sample| sample["view_component"]["seconds"] / sample["rest"]["seconds"] }
  result = {
    "ratio" => median.call(ratios),
    "ratios" => ratios,
    "reference_ms" => median.call(samples.map { |sample| sample["rest"]["seconds"] }) * 1000,
    "component_ms" => median.call(samples.map { |sample| sample["view_component"]["seconds"] }) * 1000,
    "reference_allocations" => median.call(samples.map { |sample| sample["rest"]["allocations"] }),
    "component_allocations" => median.call(samples.map { |sample| sample["view_component"]["allocations"] })
  }
  puts format("%-20s ratio %.3f  view_component %.3fms  rest of boot %.3fms", "boot", result["ratio"], result["component_ms"], result["reference_ms"])
  results["boot"] = result
end

git_sha = IO.popen(["git", "-C", view_component_lib, "rev-parse", "HEAD"], err: File::NULL, &:read).strip
output = {
  "ruby" => RUBY_DESCRIPTION,
  "rails" => Rails.version,
  "view_component" => ViewComponent::VERSION::STRING,
  "view_component_lib" => view_component_lib,
  "git_sha" => git_sha.empty? ? nil : git_sha,
  "passes" => passes,
  "scenarios" => results
}

if ARGV[0]
  FileUtils.mkdir_p(File.dirname(ARGV[0]))
  File.write(ARGV[0], JSON.pretty_generate(output))
end
