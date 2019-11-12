# frozen_string_literal: true

require "rails/application_controller"
load "config/application.rb" unless Rails.root

class Rails::ComponentExamplesController < ActionController::Base # :nodoc:
  prepend_view_path File.expand_path("templates/rails", __dir__)
  append_view_path Rails.root.join("app/views")
end
