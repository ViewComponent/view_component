# frozen_string_literal: true

require "rails"
require "view_component/config"
require "view_component/deprecation"

module ViewComponent
  class Engine < Rails::Engine # :nodoc:
    config.view_component = ViewComponent::Config.current

    if Rails.version.to_f < 8.0
      rake_tasks do
        load "view_component/rails/tasks/view_component.rake"
      end
    else
      initializer "view_component.stats_directories" do |app|
        require "rails/code_statistics"

        if Rails.root.join(ViewComponent::Base.view_component_path).directory?
          Rails::CodeStatistics.register_directory("ViewComponents", ViewComponent::Base.view_component_path)
        end

        if Rails.root.join("test/components").directory?
          Rails::CodeStatistics.register_directory("ViewComponent tests", "test/components", test_directory: true)
        end
      end
    end

    initializer "view_component.set_configs" do |app|
      options = app.config.view_component

      %i[generate preview_controller preview_route].each do |config_option|
        options[config_option] ||= ViewComponent::Base.public_send(config_option)
      end
      options.instrumentation_enabled = false if options.instrumentation_enabled.nil?
      options.show_previews = (Rails.env.development? || Rails.env.test?) if options.show_previews.nil?

      if options.show_previews
        # This is still necessary because when `config.view_component` is declared, `Rails.root` is unspecified.
        options.preview_paths << "#{Rails.root}/test/components/previews" if defined?(Rails.root) && Dir.exist?(
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

    initializer "view_component.enable_capture_patch" do |app|
      ActiveSupport.on_load(:view_component) do
        ActionView::Base.include(ViewComponent::CaptureCompatibility) if app.config.view_component.capture_compatibility_patch_enabled
      end
    end

    initializer "view_component.set_autoload_paths" do |app|
      options = app.config.view_component

      if options.show_previews && !options.preview_paths.empty?
        paths_to_add = options.preview_paths - ActiveSupport::Dependencies.autoload_paths
        ActiveSupport::Dependencies.autoload_paths.concat(paths_to_add) if paths_to_add.any?
      end
    end

    initializer "view_component.eager_load_actions" do
      ActiveSupport.on_load(:after_initialize) do
        ViewComponent::Base.descendants.each(&:compile) if Rails.application.config.eager_load
      end
    end

    initializer "compiler mode" do |_app|
      ViewComponent::Compiler.development_mode = (Rails.env.development? || Rails.env.test?)
    end

    config.after_initialize do |app|
      options = app.config.view_component

      if options.show_previews
        app.routes.prepend do
          preview_controller = options.preview_controller.sub(/Controller$/, "").underscore

          get(
            options.preview_route,
            to: "#{preview_controller}#index",
            as: :preview_view_components,
            internal: true
          )

          get(
            "#{options.preview_route}/*path",
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
