# frozen_string_literal: true
require "simplecov"
require "simplecov-erb"

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::ERBFormatter,
    SimpleCov::Formatter::HTMLFormatter
  ])
end

SimpleCov.minimum_coverage 98 # TODO: Get to 100!

require "bundler/setup"
require "pp"
require "pathname"
require "minitest/autorun"

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../config/environment.rb", __FILE__)
require "rails/test_help"

def with_preview_route(new_value)
  old_value = Rails.application.config.view_component.preview_route
  Rails.application.config.view_component.preview_route = new_value
  app.reloader.reload!
  yield
  Rails.application.config.view_component.preview_route = old_value
  app.reloader.reload!
end
