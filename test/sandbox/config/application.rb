# frozen_string_literal: true

require File.expand_path("boot", __dir__)

require "active_model/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"

# Track when different Rails frameworks get loaded.
# Ideally, none of them should be loaded until after initialization is complete.
# See config/initializers/zzz_complete_initialization.rb for the other half of this.
RAILS_FRAMEWORKS = [
  :action_cable,
  :action_controller,
  :action_mailer,
  :action_view,
  :active_job,
  :active_record
]
FRAMEWORK_LOAD_POINTS = {}
RAILS_FRAMEWORKS.each do |feature|
  ActiveSupport.on_load(feature) do
    FRAMEWORK_LOAD_POINTS[feature] = caller
  end
end

require "view_component"

require "haml"
require "slim"
require "jbuilder"

module Sandbox
  class Application < Rails::Application
    config.action_controller.asset_host = "http://assets.example.com"

    # Prepare test_set_no_duplicate_autoload_paths
    config.autoload_paths.push("#{config.root}/my/components/previews")
    config.view_component.preview_paths << "#{config.root}/my/components/previews"
  end
end

Sandbox::Application.config.secret_key_base = "foo"

# Don't silence library backtraces in test reports
Rails.backtrace_cleaner.remove_filters!
Rails.backtrace_cleaner.remove_silencers!
