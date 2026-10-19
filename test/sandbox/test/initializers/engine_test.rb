# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def test_set_no_duplicate_autoload_paths
    test_path = "#{Rails.root}/my/components/previews" # set in sandbox/config/application.rb
    assert_equal 1, ActiveSupport::Dependencies.autoload_paths.count(test_path)
  end

  # Non-main Ractors can't read ActionView::Resolver's class variable on Ruby 4.0,
  # so no per-request hook may read it when templates are cached.
  def test_watch_templates_registers_no_executor_hook_when_templates_are_cached
    app = app_with_new_executor

    with_template_caching { ViewComponent::CompileCache.watch_templates(app) }

    assert_empty app.executor._run_callbacks
  end

  def test_watch_templates_registers_an_executor_hook_when_templates_are_not_cached
    app = app_with_new_executor

    with_new_cache { ViewComponent::CompileCache.watch_templates(app) }

    assert_equal 1, app.executor._run_callbacks.count
  end

  private

  def app_with_new_executor
    Struct.new(:executor, :config).new(Class.new(ActiveSupport::Executor), Rails.application.config)
  end
end
