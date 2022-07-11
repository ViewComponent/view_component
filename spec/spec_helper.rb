# frozen_string_literal: true

require "bundler/setup"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "view_component/deprecation"
ViewComponent::Deprecation.behavior = :silence

require File.expand_path("../sandbox/config/environment.rb", __FILE__)
require "rspec/rails"

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers
end
