# frozen_string_literal: true

require "rails"
require "view_component/base"

module ViewComponent
  class Engine < Rails::Engine # :nodoc:
    config.view_component = ViewComponent::Base.config

    rake_tasks do
      load "view_component/rails/tasks/view_component.rake"
    end

    initializer "view_component.set_configs" do |app|
      options = app.config.view_component

      %i[generate preview_controller preview_route show_previews_source].each do |config_option|
        options[config_option] ||= ViewComponent::Base.public_send(config_option)
      end
      options.instrumentation_enabled = false if options.instrumentation_enabled.nil?
      options.render_monkey_patch_enabled = true if options.render_monkey_patch_enabled.nil?
      options.show_previews = (Rails.env.development? || Rails.env.test?) if options.show_previews.nil?

      if options.show_previews
        # This is still necessary because when `config.view_component` is declared, `Rails.root` is unspecified.
        options.preview_paths << "#{Rails.root}/test/components/previews" if defined?(Rails.root) && Dir.exist?(
          "#{Rails.root}/test/components/previews"
        )

        if options.show_previews_source
          require "method_source"

          app.config.to_prepare do
            MethodSource.instance_variable_set(:@lines_for_file, {})
          end
        end
      end
    end

    initializer "view_component.enable_instrumentation" do |app|
      ActiveSupport.on_load(:view_component) do
        if app.config.view_component.instrumentation_enabled.present?
          # :nocov:
          ViewComponent::Base.prepend(ViewComponent::Instrumentation)
          # :nocov:
        end
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

    initializer "view_component.monkey_patch_render" do |app|
      next if Rails.version.to_f >= 6.1 || !app.config.view_component.render_monkey_patch_enabled

      ActiveSupport.on_load(:action_view) do
        require "view_component/render_monkey_patch"
        ActionView::Base.prepend ViewComponent::RenderMonkeyPatch
      end

      ActiveSupport.on_load(:action_controller) do
        require "view_component/rendering_monkey_patch"
        require "view_component/render_to_string_monkey_patch"
        ActionController::Base.prepend ViewComponent::RenderingMonkeyPatch
        ActionController::Base.prepend ViewComponent::RenderToStringMonkeyPatch
      end
    end

    initializer "view_component.include_render_component" do |_app|
      next if Rails.version.to_f >= 6.1

      ActiveSupport.on_load(:action_view) do
        require "view_component/render_component_helper"
        ActionView::Base.include ViewComponent::RenderComponentHelper
      end

      ActiveSupport.on_load(:action_controller) do
        require "view_component/rendering_component_helper"
        require "view_component/render_component_to_string_helper"
        ActionController::Base.include ViewComponent::RenderingComponentHelper
        ActionController::Base.include ViewComponent::RenderComponentToStringHelper
      end
    end

    initializer "static assets" do |app|
      if app.config.view_component.show_previews
        app.middleware.use(::ActionDispatch::Static, "#{root}/app/assets/vendor")
      end
    end

    initializer "compiler mode" do |_app|
      ViewComponent::Compiler.mode = if Rails.env.development? || Rails.env.test?
        ViewComponent::Compiler::DEVELOPMENT_MODE
      else
        ViewComponent::Compiler::PRODUCTION_MODE
      end
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

      app.executor.to_run :before do
        CompileCache.invalidate! unless ActionView::Base.cache_template_loading
      end
    end
  end
end

# :nocov:
unless defined?(ViewComponent::Base)
  require "view_component/deprecation"

  ViewComponent::Deprecation.warn(
    "This manually engine loading is deprecated and will be removed in v3.0.0. " \
    'Remove `require "view_component/engine"`.'
  )

  require "view_component"
end
# :nocov:
