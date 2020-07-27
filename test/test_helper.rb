# frozen_string_literal: true
require "simplecov"
require "simplecov-console"

SimpleCov.start do
  formatter SimpleCov::Formatter::Console
end

if Rails.version.to_f < 6.1
  SimpleCov.minimum_coverage 100
end

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

def modify_file(file, content)
  filename = Rails.root.join(file)
  old_content = File.read(filename)
  begin
    File.open(filename, "wb+") { |f| f.write(content) }
    yield
  ensure
    File.open(filename, "wb+") { |f| f.write(old_content) }
  end
end

def with_default_preview_layout(layout)
  old_value = ViewComponent::Base.default_preview_layout
  ViewComponent::Base.default_preview_layout = layout
  yield
  ViewComponent::Base.default_preview_layout = old_value
end
