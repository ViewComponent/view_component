# frozen_string_literal: true

require "view_component/deprecation"

module ViewComponent
  class Config
    class << self
      # `new` without any arguments initializes the default configuration, but
      # it's important to differentiate in case that's no longer the case in
      # future.
      alias_method :default, :new

      def defaults
        ActiveSupport::OrderedOptions.new.merge!({
          generate: default_generate_options,
          previews: default_previews_options,
          instrumentation_enabled: false
        })
      end

      # @!attribute generate
      # @return [ActiveSupport::OrderedOptions]
      # The subset of configuration options relating to generators.
      #
      # All options under this namespace default to `false` unless otherwise
      # stated.
      #
      # #### `#path`
      #
      # Where to put generated components. Defaults to `app/components`:
      #
      #     config.view_component.generate.path = "lib/components"
      #
      # #### `#sidecar`
      #
      # Always generate a component with a sidecar directory:
      #
      #     config.view_component.generate.sidecar = true
      #
      # #### `#stimulus_controller`
      #
      # Always generate a Stimulus controller alongside the component:
      #
      #     config.view_component.generate.stimulus_controller = true
      #
      # #### `#typescript`
      #
      # Generate TypeScript files instead of JavaScript files:
      #
      #     config.view_component.generate.typescript = true
      #
      # #### `#locale`
      #
      # Always generate translations file alongside the component:
      #
      #     config.view_component.generate.locale = true
      #
      # #### `#distinct_locale_files`
      #
      # Always generate as many translations files as available locales:
      #
      #     config.view_component.generate.distinct_locale_files = true
      #
      # One file will be generated for each configured `I18n.available_locales`,
      # falling back to `[:en]` when no `available_locales` is defined.
      #
      # #### `#preview`
      #
      # Always generate a preview alongside the component:
      #
      #      config.view_component.generate.preview = true
      #
      # #### #preview_path
      #
      # Path to generate preview:
      #
      #      config.view_component.generate.preview_path = "test/components/previews"
      #
      # Required when there is more than one path defined in preview_paths.
      # Defaults to `""`. If this is blank, the generator will use
      # `ViewComponent.config.previews.paths` if defined,
      # `"test/components/previews"` otherwise
      #
      # #### `#use_component_path_for_rspec_tests`
      #
      # Whether to use `config.generate.path` when generating new
      # RSpec component tests:
      #
      #     config.view_component.generate.use_component_path_for_rspec_tests = true
      #
      # When set to `true`, the generator will use the `path` to
      # decide where to generate the new RSpec component test.
      # For example, if the `path` is
      # `app/views/components`, then the generator will create a new spec file
      # in `spec/views/components/` rather than the default `spec/components/`.

      # @!attribute previews
      # @return [ActiveSupport::OrderedOptions]
      # The subset of configuration options relating to previews.
      #
      # #### `#controller`
      #
      # The controller used for previewing components. Defaults to `ViewComponentsController`:
      #
      #     config.view_component.previews.controller = "MyPreviewController"
      #
      # #### `#route`
      #
      # The entry route for component previews. Defaults to `/rails/view_components`:
      #
      #     config.view_component.previews.route = "/my_previews"
      #
      # #### `#enabled`
      #
      # Whether component previews are enabled. Defaults to `true` in development and test environments:
      #
      #     config.view_component.previews.enabled = false
      #
      # #### `#default_layout`
      #
      # A custom default layout used for the previews index page and individual previews. Defaults to `nil`:
      #
      #     config.view_component.previews.default_layout = "preview_layout"
      #

      # @!attribute instrumentation_enabled
      # @return [Boolean]
      # Whether ActiveSupport notifications are enabled.
      # Defaults to `false`.

      def default_preview_paths
        (default_rails_preview_paths + default_rails_engines_preview_paths).uniq
      end

      def default_rails_preview_paths
        return [] unless defined?(Rails.root) && Dir.exist?("#{Rails.root}/test/components/previews")

        ["#{Rails.root}/test/components/previews"]
      end

      def default_rails_engines_preview_paths
        return [] unless defined?(Rails::Engine)

        registered_rails_engines_with_previews.map do |descendant|
          "#{descendant.root}/test/components/previews"
        end
      end

      def registered_rails_engines_with_previews
        Rails::Engine.descendants.select do |descendant|
          defined?(descendant.root) && Dir.exist?("#{descendant.root}/test/components/previews")
        end
      end

      def default_generate_options
        options = ActiveSupport::OrderedOptions.new(false)
        options.preview_path = ""
        options.path = "app/components"
        options
      end

      def default_previews_options
        options = ActiveSupport::OrderedOptions.new
        options.controller = "ViewComponentsController"
        options.route = "/rails/view_components"
        options.enabled = Rails.env.development? || Rails.env.test?
        options.default_layout = nil
        options.paths = default_preview_paths
        options
      end
    end

    # @!attribute current
    # @return [ViewComponent::Config]
    # Returns the current ViewComponent::Config. This is persisted against this
    # class so that config options remain accessible before the rest of
    # ViewComponent has loaded. Defaults to an instance of ViewComponent::Config
    # with all other documented defaults set.
    class_attribute :current, default: defaults, instance_predicate: false

    def initialize
      @config = self.class.defaults
    end

    delegate_missing_to :config

    private

    attr_reader :config
  end
end
