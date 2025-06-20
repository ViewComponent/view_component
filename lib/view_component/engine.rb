# frozen_string_literal: true

require "rails"
require "view_component/config"
require "view_component/deprecation"

module ViewComponent
  class Engine < Rails::Engine # :nodoc:
    config.view_component = ViewComponent::Config.current

    initializer "view_component.set_configs" do |app|
      options = app.config.view_component

      %i[generate previews].each do |config_option|
        options[config_option] ||= ViewComponent::Base.public_send(config_option)
      end
      options.instrumentation_enabled = false if options.instrumentation_enabled.nil?
      options.previews.enabled = (Rails.env.development? || Rails.env.test?) if options.previews.enabled.nil?

      if options.previews.enabled
        # This is still necessary because when `config.view_component` is declared, `Rails.root` is unspecified.
        options.previews.paths << "#{Rails.root}/test/components/previews" if defined?(Rails.root) && Dir.exist?(
          "#{Rails.root}/test/components/previews"
        )
      end
    end

    initializer "view_component.enable_instrumentation" do |app|
      ActiveSupport.on_load(:view_component) do
        if app.config.view_component.instrumentation_enabled.present?
          ViewComponent::Base.prepend(ViewComponent::Instrumentation)
        end
      end
    end

    initializer "view_component.set_autoload_paths" do |app|
      options = app.config.view_component

      if options.previews.enabled && !options.previews.paths.empty?
        paths_to_add = options.previews.paths - ActiveSupport::Dependencies.autoload_paths
        ActiveSupport::Dependencies.autoload_paths.concat(paths_to_add) if paths_to_add.any?
      end
    end

    initializer "view_component.propshaft_support" do |_app|
      ActiveSupport.on_load(:view_component) do
        if defined?(Propshaft)
          include Propshaft::Helper
        end
      end
    end

    config.after_initialize do |app|
      ActiveSupport.on_load(:view_component) do
        if defined?(Sprockets::Rails)
          include Sprockets::Rails::Helper

          # Copy relevant config to VC context
          # See: https://github.com/rails/sprockets-rails/blob/266ec49f3c7c96018dd75f9dc4f9b62fe3f7eecf/lib/sprockets/railtie.rb#L245
          self.debug_assets = app.config.assets.debug
          self.digest_assets = app.config.assets.digest
          self.assets_prefix = app.config.assets.prefix
          self.assets_precompile = app.config.assets.precompile

          self.assets_environment = app.assets
          self.assets_manifest = app.assets_manifest

          self.resolve_assets_with = app.config.assets.resolve_with

          self.check_precompiled_asset = app.config.assets.check_precompiled_asset
          self.unknown_asset_fallback = app.config.assets.unknown_asset_fallback
          # Expose the app precompiled asset check to the view
          self.precompiled_asset_checker = ->(logical_path) { app.asset_precompiled? logical_path }
        end
      end
    end

    initializer "view_component.eager_load_actions" do
      ActiveSupport.on_load(:after_initialize) do
        ViewComponent::Base.descendants.each(&:__vc_compile) if Rails.application.config.eager_load
      end
    end

    initializer "compiler mode" do |_app|
      ViewComponent::Compiler.__vc_development_mode = (Rails.env.development? || Rails.env.test?)
    end

    config.after_initialize do |app|
      options = app.config.view_component

      if options.previews.enabled
        app.routes.prepend do
          preview_controller = options.previews.controller.sub(/Controller$/, "").underscore

          get(
            options.previews.route,
            to: "#{preview_controller}#index",
            as: :preview_view_components,
            internal: true
          )

          get(
            "#{options.previews.route}/*path",
            to: "#{preview_controller}#previews",
            as: :preview_view_component,
            internal: true
          )
        end
      end

      if Rails.env.test?
        app.routes.prepend do
          get("_system_test_entrypoint", to: "view_components_system_test#system_test_entrypoint")
        end
      end

      app.executor.to_run :before do
        CompileCache.invalidate! unless ActionView::Base.cache_template_loading
      end
    end
  end
end
