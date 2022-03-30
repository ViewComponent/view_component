# frozen_string_literal: true

module ViewComponent
  class Config < ActiveSupport::InheritableOptions
    class << self
      alias default new

      def defaults
        {
          generate: ActiveSupport::OrderedOptions.new(false),
          preview_controller: "ViewComponentsController",
          preview_route: "/rails/view_components",
          show_previews_source: false,
          instrumentation_enabled: false,
          render_monkey_patch_enabled: true,
          view_component_path: "app/components",
          component_parent_class: nil,
          show_previews: Rails.env.development? || Rails.env.test?,
          use_global_output_buffer: false,
          preview_paths: default_preview_paths,
          test_controller: nil,
          default_preview_layout: nil
        }
      end

      # @!attribute generate
      # @return [ActiveSupport::OrderedOptions]
      # The subset of configuration options relating to generators.
      #
      # All options under this namespace default to `false` unless otherwise
      # stated.
      #
      # #### #sidecar
      #
      # Always generate a component with a sidecar directory:
      #
      #     config.view_component.generate.sidecar = true
      #
      # #### #stimulus_controller
      #
      # Always generate a Stimulus controller alongside the component:
      #
      #     config.view_component.generate.stimulus_controller = true
      #
      # #### #locale
      #
      # Always generate translations file alongside the component:
      #
      #     config.view_component.generate.locale = true
      #
      # #### #distinct_locale_files
      #
      # Always generate as many translations files as available locales:
      #
      #     config.view_component.generate.distinct_locale_files = true
      #
      # One file will be generated for each configured `I18n.available_locales`,
      # falling back to `[:en]` when no `available_locales` is defined.
      #
      # #### #preview
      #
      # Always generate a preview alongside the component:
      #
      #      config.view_component.generate.preview = true

      # @!attribute preview_controller
      # @return [String]
      # The controller used for previewing components.
      # Defaults to `ViewComponentsController`.

      # @!attribute preview_route
      # @return [String]
      # The entry route for component previews.
      # Defaults to `"/rails/view_components"`.

      # @!attribute show_previews_source
      # @return [Boolean]
      # Whether to display source code previews in component previews.
      # Defaults to `false`.

      # @!attribute instrumentation_enabled
      # @return [Boolean]
      # Whether ActiveSupport notifications are enabled.
      # Defaults to `false`.

      # @!attribute render_monkey_patch_enabled
      # @return [Boolean] Whether the #render method should be monkey patched.
      # If this is disabled, use `#render_component` or
      # `#render_component_to_string` instead.
      # Defaults to `true`.

      # @!attribute view_component_path
      # @return [String]
      # The path in which components, their templates, and their sidecars should
      # be stored.
      # Defaults to `"app/components"`.

      # @!attribute component_parent_class
      # @return [String]
      # The parent class from which generated components will inherit.
      # Defaults to `nil`. If this is falsy, generators will use
      # `"ApplicationComponent"` if defined, `"ViewComponent::Base"` otherwise.

      # @!attribute show_previews
      # @return [Boolean]
      # Whether component previews are enabled.
      # Defaults to `true` in development and test environments.

      # @!attribute use_global_output_buffer
      # @return [Boolean]
      # Whether to use the experimental global output buffer for all components.
      # It can be used on a per-component basis with `prepend
      # ViewComponent::GlobalOutputBuffer.`
      # Defaults to `false`.

      # @!attribute preview_paths
      # @return [Array<String>]
      # The locations in which component previews will be looked up.
      # Defaults to `['test/component/previews']` relative to your Rails root.

      # @!attribute preview_path
      # @deprecated Use #preview_paths instead. Will be removed in v3.0.0.

      # @!attribute test_controller
      # @return [String]
      # The controller used for testing components.
      # Can also be configured on a per-test basis using `#with_controller_class`.
      # Defaults to `nil`. If this is falsy, `ApplicationController` is used.

      # @!attribute default_preview_layout
      # @return [String]
      # A custom default layout used for the previews index page and individual
      # previews.
      # Defaults to `"component_preview"`.

      def default_preview_paths
        return [] unless defined?(Rails.root) && Dir.exist?("#{Rails.root}/test/components/previews")

        ["#{Rails.root}/test/components/previews"]
      end
    end

    def initialize(parent = nil)
      super.merge!(self.class.defaults)
    end

    def preview_path
      self.preview_paths
    end

    def preview_path=(new_value)
      ViewComponent::Deprecation.warn("`preview_path` will be removed in v3.0.0. Use `preview_paths` instead.")
      self.preview_paths = Array.wrap(new_value)
    end
  end
end
