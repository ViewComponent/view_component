# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"
require "rails"
require "rails/test_help"
require "view_component/test_helpers"
require "pry"

require "shared/view_components"
