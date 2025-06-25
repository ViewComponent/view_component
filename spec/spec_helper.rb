# frozen_string_literal: true

require "simplecov"
require "simplecov-console"
require "rails/version"

require "bundler/setup"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "view_component/deprecation"
ViewComponent::Deprecation.behavior = :silence

require File.expand_path("../../test/sandbox/config/environment.rb", __FILE__)
require "rspec/rails"

require "capybara/cuprite"

# Rails registers its own driver named "cuprite" which will overwrite the one we
# register here. Avoid the problem by registering the driver with a distinct name.
Capybara.register_driver(:system_test_driver) do |app|
  # Add the process_timeout option to prevent failures due to the browser
  # taking too long to start up.
  Capybara::Cuprite::Driver.new(app, {process_timeout: 60, timeout: 30})
end

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers
  config.include ViewComponent::SystemSpecHelpers, type: :feature
  config.include ViewComponent::SystemSpecHelpers, type: :system
end
