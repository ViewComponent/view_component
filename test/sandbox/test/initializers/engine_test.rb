# frozen_string_literal: true

require "test_helper"

require "open3"

class EngineTest < Minitest::Test
  def test_set_no_duplicate_autoload_paths
    test_path = "#{Rails.root}/my/components/previews" # set in sandbox/config/application.rb
    assert_equal 1, ActiveSupport::Dependencies.autoload_paths.count(test_path)
  end

  # Non-main Ractors can't read ActionView::Resolver's class variable on Ruby 4.0,
  # so the executor must not read it on every request when templates are cached.
  def test_executor_does_not_read_cache_template_loading_when_templates_are_cached
    reads, errors, status = Open3.capture3({"RAILS_ENV" => "production"}, RbConfig.ruby, "-rbundler/setup", "-e", <<~RUBY)
      require "rails"
      require "action_controller/railtie"
      require "view_component"

      class CachedTemplatesApp < Rails::Application
        config.eager_load = true
        config.enable_reloading = false
        config.secret_key_base = "test"
        config.logger = Logger.new(nil)
      end

      CachedTemplatesApp.initialize!

      reads = 0
      ActionView::Resolver.singleton_class.prepend(Module.new { define_method(:caching?) { reads += 1; super() } })
      CachedTemplatesApp.executor.wrap {}
      print reads
    RUBY

    assert status.success?, errors
    assert_equal "0", reads
  end
end
