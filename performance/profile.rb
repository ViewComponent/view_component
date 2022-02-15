# frozen_string_literal: true

require "ruby-prof"
require "ruby-prof-flamegraph"

# Configure Rails Environment
ENV["RAILS_ENV"] = "production"
require File.expand_path("../test/sandbox/config/environment.rb", __dir__)

module Performance
  require_relative "components/name_component.rb"
  require_relative "components/nested_name_component.rb"
  require_relative "components/inline_component.rb"
end

class BenchmarksController < ActionController::Base
end

BenchmarksController.view_paths = [File.expand_path("./views", __dir__)]

# profile the code
result = RubyProf.profile do
  1000.times do
    controller_view = BenchmarksController.new.view_context
    controller_view.render(Performance::NameComponent.new(name: "Fox Mulder"))
  end
end

# print a graph profile to text
printer = RubyProf::FlameGraphPrinter.new(result)
printer.print(STDOUT, {})
