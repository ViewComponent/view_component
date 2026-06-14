# frozen_string_literal: true

require "simplecov"
require "simplecov-console"
require "rails/version"

require "bundler/setup"

module Warning
  PROJECT_ROOT = File.expand_path("..", __dir__).freeze

  def self.warn(message)
    called_by = caller_locations(1, 1).first.path
    return super unless called_by&.start_with?(PROJECT_ROOT) && !called_by.start_with?("#{PROJECT_ROOT}/vendor")
    return if message.include?("Template format for")

    raise "Warning: #{message}"
  end
end

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
