# frozen_string_literal: true

require "allocation_stats"
require "rails/version"
require "bundler/setup"
require "pathname"
require "minitest/autorun"

if ENV["RAISE_ON_WARNING"]
  module Warning
    PROJECT_ROOT = File.expand_path("..", __dir__).freeze

    def self.warn(message)
      called_by = caller_locations(1, 1).first.path
      return super unless called_by&.start_with?(PROJECT_ROOT) && !called_by.start_with?("#{PROJECT_ROOT}/vendor")

      raise "Warning: #{message}"
    end
  end
end

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "view_component/deprecation"
ViewComponent::Deprecation.behavior = :silence

require File.expand_path("sandbox/config/environment.rb", __dir__)
require "rails/test_help"

require "capybara/cuprite"

# Rails registers its own driver named "cuprite" which will overwrite the one we
# register here. Avoid the problem by registering the driver with a distinct name.
Capybara.register_driver(:system_test_driver) do |app|
  # Add the process_timeout option to prevent failures due to the browser
  # taking too long to start up.
  Capybara::Cuprite::Driver.new(app, {process_timeout: 60, timeout: 30})
end

# Reduce extra logs produced by puma booting up
Capybara.server = :puma, {Silent: true}
# Increase the max wait time to appease test failures due to timeouts.
Capybara.default_max_wait_time = 30

def with_config_option(option_name, new_value, config_entrypoint: Rails.application.config.view_component)
  old_value = config_entrypoint.public_send(option_name)
  config_entrypoint.public_send(:"#{option_name}=", new_value)
  yield
ensure
  config_entrypoint.public_send(:"#{option_name}=", old_value)
end

# Sets custom preview paths in tests.
#
# @param new_value [Array<String>] List of preview paths
# @yield Test code to run
# @return [void]
def with_preview_paths(new_value, &block)
  with_previews_option(:paths, new_value, &block)
end

def with_preview_route(new_value, &block)
  old_value = Rails.application.config.view_component.previews.route
  Rails.application.config.view_component.previews.route = new_value
  app.reloader.reload!
  yield
ensure
  Rails.application.config.view_component.previews.route = old_value
  app.reloader.reload!
end

def with_preview_controller(new_value, &block)
  old_value = Rails.application.config.view_component.previews.controller
  Rails.application.config.view_component.previews.controller = new_value
  app.reloader.reload!
  yield
ensure
  Rails.application.config.view_component.previews.controller = old_value
  app.reloader.reload!
end

def with_custom_component_path(new_value, &block)
  with_generate_option(:path, new_value, &block)
end

def with_custom_parent_class(new_value, &block)
  with_generate_option(:parent_class, new_value, &block)
end

def with_application_component_class
  Object.const_set(:ApplicationComponent, Class.new(Object))
  yield
ensure
  Object.send(:remove_const, :ApplicationComponent)
end

def with_generate_option(config_option, value)
  old_value = Rails.application.config.view_component.generate[config_option]
  Rails.application.config.view_component.generate[config_option] = value
  yield
ensure
  Rails.application.config.view_component.generate[config_option] = old_value
end

def with_previews_option(config_option, value)
  old_value = Rails.application.config.view_component.previews[config_option]
  Rails.application.config.view_component.previews[config_option] = value
  yield
ensure
  Rails.application.config.view_component.previews[config_option] = old_value
end

def with_instrumentation_enabled_option(value)
  old_value = Rails.application.config.view_component.instrumentation_enabled
  Rails.application.config.view_component.instrumentation_enabled = value
  yield
ensure
  Rails.application.config.view_component.instrumentation_enabled = old_value
end

def with_generate_sidecar(enabled, &block)
  with_generate_option(:sidecar, enabled, &block)
end

def with_template_caching
  old_cache_template_loading = ActionView::Base.cache_template_loading
  ActionView::Base.cache_template_loading = true

  yield
ensure
  ActionView::Base.cache_template_loading = old_cache_template_loading
end

def with_new_cache
  old_cache = ViewComponent::CompileCache.cache
  ViewComponent::CompileCache.cache = Set.new
  old_cache_template_loading = ActionView::Base.cache_template_loading
  ActionView::Base.cache_template_loading = false

  yield
ensure
  ActionView::Base.cache_template_loading = old_cache_template_loading
  ViewComponent::CompileCache.cache = old_cache
end

def without_template_annotations(&block)
  old_value = ActionView::Base.annotate_rendered_view_with_filenames
  ActionView::Base.annotate_rendered_view_with_filenames = false
  app.reloader.reload! if defined?(app)

  with_new_cache(&block)

  ActionView::Base.annotate_rendered_view_with_filenames = old_value
  app.reloader.reload! if defined?(app)
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

def with_default_preview_layout(layout, &block)
  with_previews_option(:default_layout, layout, &block)
end

def with_compiler_development_mode(mode)
  previous_mode = ViewComponent::Compiler.__vc_development_mode
  ViewComponent::Compiler.__vc_development_mode = mode
  yield
ensure
  ViewComponent::Compiler.__vc_development_mode = previous_mode
end

def capture_warnings(&block)
  [].tap do |warnings|
    Kernel.stub(:warn, ->(msg) { warnings << msg }) do
      yield
    end
  end
end

def assert_allocations(count_map, &block)
  trace = AllocationStats.trace(&block)
  total = trace.allocations.all.size
  count = count_map[RUBY_VERSION.split(".").first(2).join(".")]

  assert_equal count, total, "Expected #{count} allocations, got #{total} allocations for Ruby #{RUBY_VERSION}"
end
