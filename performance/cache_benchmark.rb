# frozen_string_literal: true

require "benchmark/ips"

# Configure Rails Environment
ENV["RAILS_ENV"] = "production"
require File.expand_path("../test/sandbox/config/environment.rb", __dir__)

Rails.logger.level = 1

module Performance
  require_relative "components/cacheable_benchmark_component"
  require_relative "components/non_cacheable_benchmark_component"
end

class BenchmarksController < ActionController::Base
end

ActionController::Base.perform_caching = true
original_cache = Rails.cache
Rails.cache = ActiveSupport::Cache::MemoryStore.new(size: 64.megabytes)
Rails.cache.clear

BenchmarksController.view_paths = [File.expand_path("./views", __dir__)]
controller_view = BenchmarksController.new.view_context

cacheable_warm_component = Performance::CacheableBenchmarkComponent.new(name: "Fox Mulder")
non_cacheable_component = Performance::NonCacheableBenchmarkComponent.new(name: "Fox Mulder")
cache_miss_counter = 0

# Prime compile + cache so we benchmark steady-state behavior.
controller_view.render(cacheable_warm_component)
controller_view.render(non_cacheable_component)

begin
  Benchmark.ips do |x|
    x.time = ENV.fetch("BENCHMARK_TIME", "20").to_i
    x.warmup = ENV.fetch("BENCHMARK_WARMUP", "5").to_i

    x.report("non_cacheable") do
      controller_view.render(non_cacheable_component)
    end

    x.report("cacheable_miss") do
      cache_miss_counter += 1
      controller_view.render(Performance::CacheableBenchmarkComponent.new(name: "Fox Mulder #{cache_miss_counter}"))
    end

    x.report("cacheable_hit") do
      controller_view.render(cacheable_warm_component)
    end

    x.compare!
  end
ensure
  Rails.cache = original_cache
end
