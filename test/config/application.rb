# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "view_component/engine"
require "sprockets/railtie"

require "haml"
require "slim"

module Dummy
  class Application < Rails::Application
    config.action_controller.asset_host = "http://assets.example.com"

    config.after_initialize do |app|
      require "view_component/i18n"
      ViewComponent::I18n.initialize_i18n(app)
    end
  end
end

Dummy::Application.config.secret_key_base = "foo"
