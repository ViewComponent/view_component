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
        ActiveSupport::OrderedOptions[
          generate: ActiveSupport::OrderedOptions[
            sidecar: false,
            stimulus_controller: false,
            typescript: false,
            locale: false,
            distinct_locale_files: false,
            preview: false,
            preview_path: "",
            use_component_path_for_rspec_tests: false,
            view_component_paths: ["app/components"],
            component_parent_class: nil
          ],
          previews: ActiveSupport::OrderedOptions[
            show: (Rails.env.development? || Rails.env.test?),
            controller: "ViewComponentsController",
            route: "/rails/view_components",
            show_source: (Rails.env.development? || Rails.env.test?),
            paths: ViewComponent::Config.default_preview_paths,
            default_layout: nil
          ],
          instrumentation_enabled: false,
          test_controller: "ApplicationController",
          capture_compatibility_patch_enabled: false,
        ]
      end

      # @!attribute generate
      # @return [ActiveSupport::OrderedOptions]
      # The subset of configuration options relating to generators.
      #
      # All options under this namespace default to `false` unless otherwise
      # stated.
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
      # `ViewComponent.config.preview_paths` if defined,
      # `"test/components/previews"` otherwise
      #
      # #### `#use_component_path_for_rspec_tests`
      #
      # Whether to use the `config.view_component_path` when generating new
      # RSpec component tests:
      #
      #     config.view_component.generate.use_component_path_for_rspec_tests = true
      #
      # When set to `true`, the generator will use the `view_component_path` to
      # decide where to generate the new RSpec component test.
      # For example, if the `view_component_path` is
      # `app/views/components`, then the generator will create a new spec file
      # in `spec/views/components/` rather than the default `spec/components/`.
      #
      # #### `#view_component_path``
      #
      # The path in which components, their templates, and their sidecars should
      # be stored:
      #
      #      config.view_component.generate.view_component_paths = "app/components"
      #
      # Defaults to `"app/components"`.
      # TODO: It looks like this was actually the default path generators would use.
      #       I think it's used elsewhere inside `base.rb` for some reason, though.
      #
      # #### `#component_parent_class`
      # 
      # The parent class from which generated components will inherit.
      # Defaults to `nil`. If this is falsy, generators will use
      # `"ApplicationComponent"` if defined, `"ViewComponent::Base"` otherwise.

      
      # @!attribute previews
      # @return [String]
      # The subset of configuration options relating to previews.
      #
      # #### `#show`
      #
      # Whether component previews are enabled.
      # Defaults to `true` in development and test environments.
      #
      # #### `#controller`
      #
      # The controller used for previewing components.
      # Defaults to `ViewComponentsController`.
      #
      # #### `route`
      #
      # The entry route for component previews.
      # Defaults to `"/rails/view_components"`.
      #
      # #### `show_source`
      #
      # Whether to display source code previews in component previews.
      # Defaults to `false`.
      # 
      # #### `paths`
      #
      # The locations in which component previews will be looked up.
      # Defaults to `['test/components/previews']` relative to your Rails root.
      #
      # #### `#default_layout`
      # 
      # A custom default layout used for the previews index page and individual
      # previews.
      # Defaults to `nil`. If this is falsy, `"component_preview"` is used.

      # @!attribute instrumentation_enabled
      # @return [Boolean]
      # Whether ActiveSupport notifications are enabled.
      # Defaults to `false`.

      # @!attribute test_controller
      # @return [String]
      # The controller used for testing components.
      # Can also be configured on a per-test basis using `#with_controller_class`.
      # Defaults to `ApplicationController`.

      # @!attribute capture_compatibility_patch_enabled
      # @return [Boolean]
      # Enables the experimental capture compatibility patch that makes ViewComponent
      # compatible with forms, capture, and other built-ins.
      # previews.
      # Defaults to `false`.

      def default_preview_paths
        (default_rails_preview_paths + default_rails_engines_preview_paths).uniq
      end

      def default_rails_preview_paths
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
    end

    def initialize
      @config = self.class.defaults
    end

    delegate_missing_to :config

    private

    attr_reader :config
  end
end
