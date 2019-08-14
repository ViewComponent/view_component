# frozen_string_literal: true

require "bundler/setup"
require "pp"
require "pathname"
root_path = Pathname(File.expand_path("../..", __FILE__))
$LOAD_PATH.unshift root_path.join("lib").to_s
require "minitest/autorun"
require "action_view/component_test_helpers"

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../config/environment.rb", __FILE__)
require "rails/test_help"

def trim_result(html)
  html.delete(" \t\r\n")
end
