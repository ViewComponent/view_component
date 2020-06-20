# frozen_string_literal: true

require "rails"
require "view_component"

module ViewComponent
  class Engine < Rails::Engine # :nodoc:
    config.view_component = ActiveSupport::OrderedOptions.new
    config.view_component.preview_paths ||= []

    initializer "view_component.set_configs" do |app|
      options = app.config.view_component

      options.show_previews = Rails.env.development? if options.show_previews.nil?
      options.preview_route ||= ViewComponent::Base.preview_route

      if options.show_previews
        options.preview_paths << "#{Rails.root}/test/components/previews" if defined?(Rails.root)
      end

      ActiveSupport.on_load(:view_component) do
        options.each { |k, v| send("#{k}=", v) }
      end
    end

    initializer "view_component.set_autoload_paths" do |app|
      options = app.config.view_component

      if options.show_previews && options.preview_path
        ActiveSupport::Dependencies.autoload_paths << options.preview_path
      end
    end

    initializer "view_component.eager_load_actions" do
      ActiveSupport.on_load(:after_initialize) do
        ViewComponent::Base.descendants.each(&:compile)
      end
    end

    initializer "view_component.compile_config_methods" do
      ActiveSupport.on_load(:view_component) do
        config.compile_methods! if config.respond_to?(:compile_methods!)
      end
    end

    initializer "view_component.monkey_patch_render" do
      ActiveSupport.on_load(:action_view) do
        if Rails.version.to_f < 6.1
          require "view_component/render_monkey_patch"
          ActionView::Base.prepend ViewComponent::RenderMonkeyPatch
        end
      end

      ActiveSupport.on_load(:action_controller) do
        if Rails.version.to_f < 6.1
          require "view_component/rendering_monkey_patch"
          require "view_component/render_to_string_monkey_patch"
          ActionController::Base.prepend ViewComponent::RenderingMonkeyPatch
          ActionController::Base.prepend ViewComponent::RenderToStringMonkeyPatch
        end
      end
    end

    config.after_initialize do |app|
      options = app.config.view_component

      if options.show_previews
        app.routes.prepend do
          get options.preview_route, to: "view_components#index", as: :preview_view_components, internal: true
          get "#{options.preview_route}/*path", to: "view_components#previews", as: :preview_view_component, internal: true
        end
      end

      app.executor.to_run :before do
        CompileCache.invalidate! unless ActionView::Base.cache_template_loading
      end
    end
  end
end
