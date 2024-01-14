# frozen_string_literal: true

require "simplecov"
require "simplecov-console"
require "rails/version"

if ENV["MEASURE_COVERAGE"]
  SimpleCov.start do
    command_name "minitest-rails-engine#{Rails::VERSION::STRING}-ruby#{RUBY_VERSION}"

    formatter SimpleCov::Formatter::Console
  end
end
require "rails/engine"
require "view_component"
require "dummy"
require_relative "app/components/dummy/example_component"
require "bundler/setup"
require "minitest/autorun"
