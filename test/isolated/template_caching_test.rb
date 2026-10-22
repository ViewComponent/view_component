# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "minitest/mock"
require "tmpdir"
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

  # Applications and engines often add autoload paths as Pathnames, which
  # ActiveSupport::FileUpdateChecker can't build its glob from.
  def test_executor_watches_autoload_paths_given_as_pathnames
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "lib/components"))
      app = boot_app("development", root: root) do
        config.autoload_paths << Pathname.new(root).join("lib/components")
      end
      refute ActionView::Base.cache_template_loading

      app.executor.wrap {}
    end
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

  def test_template_changes_are_not_reflected_on_new_request_when_templates_are_cached
    Dir.mktmpdir do |root|
      write_file(root, "app/components/greeting_component.rb", "class GreetingComponent < ViewComponent::Base; end")
      write_file(root, "app/components/greeting_component.html.erb", "<div>Hello</div>")

      app = boot_app("production", root: root)
      app.routes.draw do
        get "/", to: ->(_env) { [200, {"content-type" => "text/html"}, [ActionController::Base.render(GreetingComponent.new)]] }
      end
      request = Rack::MockRequest.new(app)

      assert_equal "<div>Hello</div>", request.get("/").body.strip

      write_file(root, "app/components/greeting_component.html.erb", "<div>Goodbye</div>")

      assert_equal "<div>Hello</div>", request.get("/").body.strip
    end
  end

  def test_component_digests_are_computed_at_boot_when_templates_are_cached
    Dir.mktmpdir do |root|
      write_file(root, "app/components/greeting_component.rb", "class GreetingComponent < ViewComponent::Base; end")
      write_file(root, "app/components/greeting_component.html.erb", "<div>Hello</div>")

      boot_app("production", root: root)
      finder = ActionView::LookupContext.new(ActionController::Base.view_paths, formats: [:html])

      assert GreetingComponent.__vc_cache_digest_source
      assert finder.digest_cache["view_component/cache_digest/greeting_component.html"]
    end
  end

  def test_component_digests_are_not_computed_at_boot_when_templates_are_not_cached
    Dir.mktmpdir do |root|
      write_file(root, "app/components/greeting_component.rb", "class GreetingComponent < ViewComponent::Base; end")
      write_file(root, "app/components/greeting_component.html.erb", "<div>Hello</div>")

      boot_app("development", root: root)

      assert_nil GreetingComponent.__vc_cache_digest_source
    end
  end

  private

  def boot_app(env, root: __dir__, &configure)
    Rails.env = env

    Class.new(Rails::Application) do
      config.root = root
      config.eager_load = env == "production"
      config.enable_reloading = env == "development"
      config.secret_key_base = "test"
      config.logger = Logger.new(nil)
      class_eval(&configure) if configure
    end.tap(&:initialize!)
  end

  def write_file(root, path, content)
    FileUtils.mkdir_p(File.dirname(File.join(root, path)))
    File.write(File.join(root, path), content)
  end
end
