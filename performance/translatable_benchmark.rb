# frozen_string_literal: true

# Run `bundle exec rake benchmark` to execute benchmark.
# This is very much a work-in-progress. Please feel free to make/suggest improvements!

require "benchmark/ips"

# Configure Rails Environment
ENV["RAILS_ENV"] = "production"
require File.expand_path("../test/sandbox/config/environment.rb", __dir__)

module Performance
  require_relative "components/global_i18n_component"
  require_relative "components/translatable_component"
end

class BenchmarksController < ActionController::Base
end

BenchmarksController.view_paths = [File.expand_path("./views", __dir__)]
controller_view = BenchmarksController.new.view_context
I18n.load_path = Dir[File.expand_path("../test/sandbox/config/locales/*.{rb,yml,yaml}", __dir__)]
I18n.backend.load_translations

global_i18n_component = Performance::GlobalI18nComponent.new("hello")
translatable_component = Performance::TranslatableComponent.new(".hello")

controller_view.render(global_i18n_component)
controller_view.render(translatable_component)

Benchmark.ips do |x|
  x.report(:global) { global_i18n_component.t("hello") }
  x.report(:sidecar) { translatable_component.t(".hello") }

  x.report(:global_missing) { global_i18n_component.t("missing") }
  x.report(:sidecar_missing) { translatable_component.t("missing") }

  x.report(:sidecar_absolute) { translatable_component.t("translatable_component.hello") }
  x.report(:sidecar_fallback) { translatable_component.t("from.rails") }

  x.compare!
end
