# frozen_string_literal: true

require "simplecov"
require "simplecov-console"

require "bundler/setup"
require "minitest/autorun"
require "rails"
require "rails/generators"
$LOAD_PATH.unshift "./test/test_engine/lib"
require "test_engine"
require "view_component"

Rails::Generators.namespace = TestEngine

def with_config_option(option_name, new_value, config_entrypoint: TestEngine::Engine.config.view_component)
  old_value = config_entrypoint.public_send(option_name)
  config_entrypoint.public_send(:"#{option_name}=", new_value)
  yield
ensure
  config_entrypoint.public_send(:"#{option_name}=", old_value)
end

def with_preview_paths(new_value, config_entrypoint: TestEngine::Engine.config.view_component, &block)
  old_value = config_entrypoint.previews.paths
  config_entrypoint.previews.paths = new_value
  yield
ensure
  config_entrypoint.previews.paths = old_value
end
