# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "minitest/mock"
require "rails"
require "action_controller/railtie"
require "active_support/testing/isolation"
require "view_component"

# Boots a fresh application per test in a forked process, so tests can choose
# their own environment. Runs separately from the sandbox, which boots in test.
class TemplateCachingTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  def test_executor_checks_for_template_changes_when_templates_are_not_cached
    app = boot_app("development")
    refute ActionView::Base.cache_template_loading

    watcher = Minitest::Mock.new
    watcher.expect(:execute_if_updated, nil)
    ViewComponent::CompileCache.stub(:template_watcher, watcher) { app.executor.wrap {} }

    watcher.verify
  end

  # Non-main Ractors can't read ActionView::Resolver's class variable on Ruby 4.0,
  # so the executor must not read it on every request when templates are cached.
  def test_executor_does_nothing_when_templates_are_cached
    app = boot_app("production")
    assert ActionView::Base.cache_template_loading

    reads = 0
    ActionView::Resolver.singleton_class.prepend(Module.new do
      define_method(:caching?) do
        reads += 1
        super()
      end
    end)
    ViewComponent::CompileCache.stub(:template_watcher, ->(*) { flunk "templates were watched" }) { app.executor.wrap {} }

    assert_equal 0, reads
  end

  private

  def boot_app(env)
    Rails.env = env

    Class.new(Rails::Application) do
      config.root = __dir__
      config.eager_load = env == "production"
      config.enable_reloading = env == "development"
      config.secret_key_base = "test"
      config.logger = Logger.new(nil)
    end.tap(&:initialize!)
  end
end
