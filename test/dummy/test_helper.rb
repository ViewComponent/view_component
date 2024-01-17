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
require "bundler/setup"
require "minitest/autorun"
require "rails"
require "rails/generators"
$LOAD_PATH.unshift "./test/dummy/lib"
require "dummy"
require "view_component"

Rails::Generators.namespace = Dummy
