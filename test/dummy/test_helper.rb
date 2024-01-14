# frozen_string_literal: true

require "simplecov"
require "simplecov-console"
require "rails"

if ENV["MEASURE_COVERAGE"]
  SimpleCov.start do
    command_name "minitest-rails#{Rails::VERSION::STRING}-ruby#{RUBY_VERSION}"

    formatter SimpleCov::Formatter::Console
  end
end

require "view_component"
require "dummy"
