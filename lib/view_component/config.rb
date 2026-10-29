# frozen_string_literal: true

require "view_component/errors"

module ViewComponent
  class Config
    # An `ActiveSupport::OrderedOptions` that raises when an option it doesn't
    # know about is set, rather than silently storing it.
    class Options < ActiveSupport::OrderedOptions # :nodoc:
      ROOT_NAMESPACE = "config.view_component"

      def initialize(namespace, allowed_keys, default: nil, renamed: {}, removed: {})
        super(default)
        @namespace = namespace
        @allowed_keys = allowed_keys
        @renamed = renamed
        @removed = removed
        @nested_options = {}
      end

      def []=(key, value)
        key = key.to_sym

        if @allowed_keys.include?(key)
          @nested_options[key] ||= value if value.is_a?(Options)
          if (nested_options = @nested_options[key])
            raise TypeError, "#{@namespace}.#{key} must be a Hash" unless value.is_a?(Hash)

            value = nested_options.dup.clear.tap do |options|
              value.each_pair { |nested_key, nested_value| options[nested_key] = nested_value }
            end
          end

          super
        else
          raise UnknownConfigOptionError.new(
            "#{@namespace}.#{key}",
            renamed_to: @renamed[key] && "#{ROOT_NAMESPACE}.#{@renamed[key]}",
            removed: @removed.key?(key),
            hint: @removed[key],
            valid_options: @allowed_keys
          )
        end
      end

      alias_method :store, :[]=

      def merge!(*others)
        others.each do |other|
          {}.merge!(other).each_pair do |key, value|
            key = key.to_sym
            value = yield(key, self[key], value) if block_given? && key?(key)
            self[key] = value
          end
        end
        self
      end

      alias_method :update, :merge!

      def replace(other)
        replacement = dup.clear
        replacement.merge!(other)
        super(replacement)
      end

      def transform_keys!(*args, &block)
        return enum_for(:transform_keys!) if args.empty? && !block

        replace(to_h.transform_keys!(*args, &block))
      end

      def transform_values!(&block)
        return enum_for(:transform_values!) unless block

        replace(to_h.transform_values!(&block))
      end
    end

    # Options renamed in 4.0, mapped to their new name.
    RENAMED_OPTIONS = {
      preview_controller: "previews.controller",
      preview_route: "previews.route",
      preview_paths: "previews.paths",
      show_previews: "previews.enabled",
      default_preview_layout: "previews.default_layout",
      component_parent_class: "generate.parent_class",
      view_component_path: "generate.path"
    }.freeze

    # Options removed in 4.0, mapped to a hint about what to do instead.
    REMOVED_OPTIONS = {
      test_controller: "Use the `vc_test_controller_class` test helper instead.",
      render_monkey_patch_enabled: nil,
      use_deprecated_instrumentation_name: "Events always use the `render.view_component` name.",
      capture_compatibility_patch_enabled: nil,
      show_previews_source: "Consider using Lookbook instead."
    }.freeze

    class << self
      # `new` without any arguments initializes the default configuration, but
      # it's important to differentiate in case that's no longer the case in
      # future.
      alias_method :default, :new

      def defaults
        options = Options.new(
          Options::ROOT_NAMESPACE,
          %i[generate previews instrumentation_enabled],
          renamed: RENAMED_OPTIONS,
          removed: REMOVED_OPTIONS
        )
        options.generate = default_generate_options
        options.previews = default_previews_options
        options.instrumentation_enabled = false
        options
      end

      # @!attribute generate
      #
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
      #
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
      #
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
        options = Options.new(
          "#{Options::ROOT_NAMESPACE}.generate",
          %i[path preview_path parent_class sidecar stimulus_controller typescript locale distinct_locale_files preview use_component_path_for_rspec_tests],
          default: false,
          renamed: {component_parent_class: RENAMED_OPTIONS.fetch(:component_parent_class)}
        )
        options.preview_path = ""
        options.path = "app/components"
        options
      end

      def default_previews_options
        options = Options.new(
          "#{Options::ROOT_NAMESPACE}.previews",
          %i[controller route enabled default_layout paths]
        )
        options.controller = "ViewComponentsController"
        options.route = "/rails/view_components"
        options.enabled = defined?(Rails.env) && (Rails.env.development? || Rails.env.test?)
        options.default_layout = nil
        options.paths = default_preview_paths
        options
      end
    end

    # @!attribute current
    #
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
