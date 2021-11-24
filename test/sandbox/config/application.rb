# frozen_string_literal: true

require "active_model/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"

require "view_component"

require "haml"
require "slim"
require "jbuilder"

module Sandbox
  class Application < Rails::Application
    config.action_controller.asset_host = "http://assets.example.com"
  end
end

Sandbox::Application.config.secret_key_base = "foo"

# Don't silence library backtraces in test reports
Rails.backtrace_cleaner.remove_filters!
Rails.backtrace_cleaner.remove_silencers!
