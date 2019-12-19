# frozen_string_literal: true

require "bundler/setup"
require "pp"
require "pathname"
require "action_view/component"
require "minitest/autorun"

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require "rails/test_help"
