# frozen_string_literal: true

require "rails"
require "view_component/config"
require "view_component/deprecation"

module ViewComponent
  class Engine < Rails::Engine # :nodoc:
    config.view_component = ViewComponent::Config.default

    if Rails.version.to_f < 8.0
      rake_tasks do
        load "view_component/rails/tasks/view_component.rake"
      end
    else
      initializer "view_component.stats_directories" do |app|
        require "rails/code_statistics"

        if Rails.root.join(Rails.application.config.view_component.generate.view_component_paths!.first).directory?
          Rails::CodeStatistics.register_directory("ViewComponents", Rails.application.config.view_component.generate.view_component_paths!.first)
        end

        if Rails.root.join("test/components").directory?
          Rails::CodeStatistics.register_directory("ViewComponent tests", "test/components", test_directory: true)
        end
      end
    end

    initializer "view_component.set_configs" do |app|
      options = app.config.view_component

      # This is still necessary because when `config.view_component` is declared, `Rails.root` is unspecified.
      options.previews.paths << "#{Rails.root}/test/components/previews" if defined?(Rails.root) && (
        "#{Rails.root}/test/components/previews"
      )
      
      # TODO: Custom error type, more informative error here
      #       Also maybe there's a better time to call this.
      # raise "Preview directories must exist" if options.show_previews && !options.preview_paths.all? { |path| Dir.exist?(path) }

      if options.previews.show && options.previews.show_source
        require "method_source"

        app.config.to_prepare do
          MethodSource.instance_variable_set(:@lines_for_file, {})
        end
      end
    end

    initializer "view_component.enable_instrumentation" do |app|
      ActiveSupport.on_load(:view_component) do
        if app.config.view_component.instrumentation_enabled.present?
          # :nocov: Re-executing the below in tests duplicates initializers and causes order-dependent failures.
          ViewComponent::Base.prepend(ViewComponent::Instrumentation)
          # :nocov:
        end
      end
    end

    # :nocov:
    initializer "view_component.enable_capture_patch" do |app|
      ActiveSupport.on_load(:view_component) do
        ActionView::Base.include(ViewComponent::CaptureCompatibility) if app.config.view_component.capture_compatibility_patch_enabled
      end
    end
    # :nocov:

    initializer "view_component.set_autoload_paths" do |app|
      options = app.config.view_component

      if options.previews.show && !options.previews.paths.empty?
        paths_to_add = options.previews.paths - ActiveSupport::Dependencies.autoload_paths
        ActiveSupport::Dependencies.autoload_paths.concat(paths_to_add) if paths_to_add.any?
      end
    end

    initializer "view_component.eager_load_actions" do
      ActiveSupport.on_load(:after_initialize) do
        ViewComponent::Base.descendants.each(&:compile) if Rails.application.config.eager_load
      end
    end

    initializer "static assets" do |app|
      if serve_static_preview_assets?(app.config)
        app.middleware.use(::ActionDispatch::Static, "#{root}/app/assets/vendor")
      end
    end

    def serve_static_preview_assets?(app_config)
      app_config.view_component.previews.show && app_config.public_file_server.enabled
    end

    initializer "compiler mode" do |_app|
      ViewComponent::Compiler.development_mode = (Rails.env.development? || Rails.env.test?)
    end

    config.after_initialize do |app|
      options = app.config.view_component

      if options.previews.show
        app.routes.prepend do
          preview_controller = options.previews.controller!.sub(/Controller$/, "").underscore

          get(
            options.previews.route!,
            to: "#{preview_controller}#index",
            as: :preview_view_components,
            internal: true
          )

          get(
            "#{options.previews.route!}/*path",
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
