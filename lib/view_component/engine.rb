# frozen_string_literal: true

require "rails"
require "view_component"

module ViewComponent
  class Engine < Rails::Engine # :nodoc:
    config.action_view_component = ActiveSupport::OrderedOptions.new

    config.before_configuration do |app|
      app.config.paths.add "app/components", eager_load: true
    end

    initializer "action_view_component.set_configs" do |app|
      options = app.config.action_view_component

      options.show_previews = Rails.env.development? if options.show_previews.nil?

      if options.show_previews
        options.preview_path ||= defined?(Rails.root) ? "#{Rails.root}/test/components/previews" : nil
      end

      ActiveSupport.on_load(:action_view_component) do
        options.each { |k, v| send("#{k}=", v) }
      end
    end

    initializer "action_view_component.set_autoload_paths" do |app|
      options = app.config.action_view_component

      if options.show_previews && options.preview_path
        ActiveSupport::Dependencies.autoload_paths << options.preview_path
      end
    end

    initializer "action_view_component.compile_config_methods" do
      ActiveSupport.on_load(:action_view_component) do
        config.compile_methods! if config.respond_to?(:compile_methods!)
      end
    end

    initializer "action_view_component.monkey_patch_render" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Base.prepend ViewComponent::RenderMonkeyPatch
      end

      ActiveSupport.on_load(:action_controller) do
        ActionController::Base.prepend ViewComponent::RenderingMonkeyPatch
      end
    end

    initializer "action_view_component.add_components_view_paths" do |app|
      views = app.config.paths["app/components"].existent
      unless views.empty?
        ActiveSupport.on_load(:action_view_component) { prepend_view_path(views) if respond_to?(:prepend_view_path) }
      end
    end

    config.after_initialize do |app|
      options = app.config.action_view_component

      if options.show_previews
        app.routes.prepend do
          get "/rails/components"       => "rails/components#index", :internal => true
          get "/rails/components/*path" => "rails/components#previews", :internal => true
        end
      end
    end
  end
end
