# frozen_string_literal: true

require "benchmark/ips"

ENV["RAILS_ENV"] = "production"
require File.expand_path("../test/sandbox/config/environment.rb", __dir__)

Rails.logger.level = 1

module Performance
  require_relative "components/handler_benchmark_component"
  require_relative "components/erb_cached_benchmark_component"
  require_relative "components/erb_uncached_benchmark_component"
  require_relative "components/slim_cached_benchmark_component"
  require_relative "components/slim_uncached_benchmark_component"
  require_relative "components/haml_cached_benchmark_component"
  require_relative "components/haml_uncached_benchmark_component"
  require_relative "components/jbuilder_cached_benchmark_component"
  require_relative "components/jbuilder_uncached_benchmark_component"
end

class HandlerBenchmarksController < ActionController::Base
end

ActionController::Base.perform_caching = true
original_cache = Rails.cache
Rails.cache = ActiveSupport::Cache::MemoryStore.new(size: 64.megabytes)
Rails.cache.clear

HandlerBenchmarksController.view_paths = [File.expand_path("./views", __dir__)]
html_view = HandlerBenchmarksController.new.view_context
json_view = HandlerBenchmarksController.new.view_context
json_view.lookup_context.formats = [:json]

BENCHMARKS = {
  erb: {
    view: html_view,
    cached: Performance::ErbCachedBenchmarkComponent,
    uncached: Performance::ErbUncachedBenchmarkComponent
  },
  slim: {
    view: html_view,
    cached: Performance::SlimCachedBenchmarkComponent,
    uncached: Performance::SlimUncachedBenchmarkComponent
  },
  haml: {
    view: html_view,
    cached: Performance::HamlCachedBenchmarkComponent,
    uncached: Performance::HamlUncachedBenchmarkComponent
  },
  jbuilder: {
    view: json_view,
    cached: Performance::JbuilderCachedBenchmarkComponent,
    uncached: Performance::JbuilderUncachedBenchmarkComponent
  }
}.freeze

cache_miss_counters = Hash.new(0)

BENCHMARKS.each do |handler, config|
  config[:warm_component] = config[:cached].new(name: "#{handler} cached")
  config[:uncached_component] = config[:uncached].new(name: "#{handler} uncached")

  config[:view].render(config[:warm_component])
  config[:view].render(config[:uncached_component])
end

begin
  Benchmark.ips do |x|
    x.time = ENV.fetch("BENCHMARK_TIME", "20").to_i
    x.warmup = ENV.fetch("BENCHMARK_WARMUP", "5").to_i

    BENCHMARKS.each do |handler, config|
      x.report("#{handler}_without_cache") do
        config[:view].render(config[:uncached_component])
      end

      x.report("#{handler}_cache_miss") do
        cache_miss_counters[handler] += 1
        config[:view].render(config[:cached].new(name: "#{handler} miss #{cache_miss_counters[handler]}x"))
      end

      x.report("#{handler}_cache_hit") do
        config[:view].render(config[:warm_component])
      end
    end

    x.compare!
  end
ensure
  Rails.cache = original_cache
end
