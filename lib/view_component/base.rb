# frozen_string_literal: true

require "action_view"
require "active_support/configurable"
require "view_component/collection"
require "view_component/compile_cache"
require "view_component/compiler"
require "view_component/config"
require "view_component/content_areas"
require "view_component/polymorphic_slots"
require "view_component/preview"
require "view_component/slotable"
require "view_component/slotable_v2"
require "view_component/translatable"
require "view_component/with_content_helper"

module ViewComponent
  class Base < ActionView::Base
    class << self
      delegate(*ViewComponent::Config.defaults.keys, to: :config)

      def config
        @config ||= ViewComponent::Config.defaults
      end
    end

    include ViewComponent::ContentAreas
    include ViewComponent::PolymorphicSlots
    include ViewComponent::SlotableV2
    include ViewComponent::Translatable
    include ViewComponent::WithContentHelper

    ViewContextCalledBeforeRenderError = Class.new(StandardError)

    RESERVED_PARAMETER = :content

    # For CSRF authenticity tokens in forms
    delegate :form_authenticity_token, :protect_against_forgery?, :config, to: :helpers

    class_attribute :content_areas
    self.content_areas = [] # class_attribute:default doesn't work until Rails 5.2

    # Config option that strips trailing whitespace in templates before compiling them.
    class_attribute :__vc_strip_trailing_whitespace, instance_accessor: false, instance_predicate: false
    self.__vc_strip_trailing_whitespace = false # class_attribute:default doesn't work until Rails 5.2

    attr_accessor :__vc_original_view_context

    # Components render in their own view context. Helpers and other functionality
    # require a reference to the original Rails view context, an instance of
    # `ActionView::Base`. Use this method to set a reference to the original
    # view context. Objects that implement this method will render in the component's
    # view context, while objects that don't will render in the original view context
    # so helpers, etc work as expected.
    #
    # @param view_context [ActionView::Base] The original view context.
    # @return [void]
    def set_original_view_context(view_context)
      self.__vc_original_view_context = view_context
    end

    # @!macro [attach] deprecated_generate_mattr_accessor
    #   @method generate_$1
    #   @deprecated Use `#generate.$1` instead. Will be removed in v3.0.0.
    def self._deprecated_generate_mattr_accessor(name)
      define_singleton_method("generate_#{name}".to_sym) do
        generate.public_send(name)
      end
      define_singleton_method("generate_#{name}=".to_sym) do |value|
        generate.public_send("#{name}=".to_sym, value)
      end
    end

    _deprecated_generate_mattr_accessor :distinct_locale_files
    _deprecated_generate_mattr_accessor :locale
    _deprecated_generate_mattr_accessor :sidecar
    _deprecated_generate_mattr_accessor :stimulus_controller

    # Entrypoint for rendering components.
    #
    # - `view_context`: ActionView context from calling view
    # - `block`: optional block to be captured within the view context
    #
    # Returns HTML that has been escaped by the respective template handler.
    #
    # @return [String]
    def render_in(view_context, &block)
      self.class.compile(raise_errors: true)

      @view_context = view_context
      self.__vc_original_view_context ||= view_context

      @output_buffer = ActionView::OutputBuffer.new

      @lookup_context ||= view_context.lookup_context

      # required for path helpers in older Rails versions
      @view_renderer ||= view_context.view_renderer

      # For content_for
      @view_flow ||= view_context.view_flow

      # For i18n
      @virtual_path ||= virtual_path

      # For template variants (+phone, +desktop, etc.)
      @__vc_variant ||= @lookup_context.variants.first

      # For caching, such as #cache_if
      @current_template = nil unless defined?(@current_template)
      old_current_template = @current_template
      @current_template = self

      if block && defined?(@__vc_content_set_by_with_content)
        raise ArgumentError, "It looks like a block was provided after calling `with_content` on #{self.class.name}, " \
          "which means that ViewComponent doesn't know which content to use.\n\n" \
          "To fix this issue, use either `with_content` or a block."
      end

      @__vc_content_evaluated = false
      @__vc_render_in_block = block

      before_render

      if render?
        # Ensure `content` is evaluated before rendering the template, this is
        # needed so slots and other side-effects are performed before the
        # component template is evaluated.
        content if self.class.use_consistent_rendering_lifecycle

        render_template_for(@__vc_variant).to_s + output_postamble
      else
        ""
      end
    ensure
      @current_template = old_current_template
    end

    # Subclass components that call `super` inside their template code will cause a
    # double render if they emit the result:
    #
    # ```erb
    # <%= super %> # double-renders
    # <% super %> # does not double-render
    # ```
    #
    # Calls `super`, returning `nil` to avoid rendering the result twice.
    def render_parent
      mtd = @__vc_variant ? "call_#{@__vc_variant}" : "call"
      method(mtd).super_method.call
      nil
    end

    # Optional content to be returned after the rendered template.
    #
    # @return [String]
    def output_postamble
      ""
    end

    # Called before rendering the component. Override to perform operations that
    # depend on having access to the view context, such as helpers.
    #
    # @return [void]
    def before_render
      before_render_check
    end

    # Called after rendering the component.
    #
    # @deprecated Use `#before_render` instead. Will be removed in v3.0.0.
    # @return [void]
    def before_render_check
      # noop
    end

    # Override to determine whether the ViewComponent should render.
    #
    # @return [Boolean]
    def render?
      true
    end

    # @private
    def initialize(*)
    end

    # Re-use original view_context if we're not rendering a component.
    #
    # This prevents an exception when rendering a partial inside of a component that has also been rendered outside
    # of the component. This is due to the partials compiled template method existing in the parent `view_context`,
    #  and not the component's `view_context`.
    #
    # @private
    def render(options = {}, args = {}, &block)
      if options.respond_to?(:set_original_view_context)
        options.set_original_view_context(self.__vc_original_view_context)
        super
      else
        __vc_original_view_context.render(options, args, &block)
      end
    end

    # The current controller. Use sparingly as doing so introduces coupling
    # that inhibits encapsulation & reuse, often making testing difficult.
    #
    # @return [ActionController::Base]
    def controller
      if view_context.nil?
        raise(
          ViewContextCalledBeforeRenderError,
          "`#controller` can't be used during initialization, as it depends " \
          "on the view context that only exists once a ViewComponent is passed to " \
          "the Rails render pipeline.\n\n" \
          "It's sometimes possible to fix this issue by moving code dependent on " \
          "`#controller` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."
        )
      end

      @__vc_controller ||= view_context.controller
    end

    # A proxy through which to access helpers. Use sparingly as doing so introduces
    # coupling that inhibits encapsulation & reuse, often making testing difficult.
    #
    # @return [ActionView::Base]
    def helpers
      if view_context.nil?
        raise(
          ViewContextCalledBeforeRenderError,
          "`#helpers` can't be used during initialization, as it depends " \
          "on the view context that only exists once a ViewComponent is passed to " \
          "the Rails render pipeline.\n\n" \
          "It's sometimes possible to fix this issue by moving code dependent on " \
          "`#helpers` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."
        )
      end

      # Attempt to re-use the original view_context passed to the first
      # component rendered in the rendering pipeline. This prevents the
      # instantiation of a new view_context via `controller.view_context` which
      # always returns a new instance of the view context class.
      #
      # This allows ivars to remain persisted when using the same helper via
      # `helpers` across multiple components and partials.
      @__vc_helpers ||= __vc_original_view_context || controller.view_context
    end

    # Exposes .virtual_path as an instance method
    #
    # @private
    def virtual_path
      self.class.virtual_path
    end

    # For caching, such as #cache_if
    # @private
    def view_cache_dependencies
      []
    end

    # For caching, such as #cache_if
    #
    # @private
    def format
      # Ruby 2.6 throws a warning without checking `defined?`, 2.7 doesn't
      @__vc_variant if defined?(@__vc_variant)
    end

    # Use the provided variant instead of the one determined by the current request.
    #
    # @deprecated Will be removed in v3.0.0.
    # @param variant [Symbol] The variant to be used by the component.
    # @return [self]
    def with_variant(variant)
      @__vc_variant = variant

      self
    end
    deprecate :with_variant, deprecator: ViewComponent::Deprecation

    # The current request. Use sparingly as doing so introduces coupling that
    # inhibits encapsulation & reuse, often making testing difficult.
    #
    # @return [ActionDispatch::Request]
    def request
      @request ||= controller.request if controller.respond_to?(:request)
    end

    private

    attr_reader :view_context

    def content
      @__vc_content_evaluated = true
      return @__vc_content if defined?(@__vc_content)

      @__vc_content =
        if @view_context && @__vc_render_in_block
          view_context.capture(self, &@__vc_render_in_block)
        elsif defined?(@__vc_content_set_by_with_content)
          @__vc_content_set_by_with_content
        end
    end

    def content_evaluated?
      @__vc_content_evaluated
    end

    # Set the controller used for testing components:
    #
    # ```ruby
    # config.view_component.test_controller = "MyTestController"
    # ```
    #
    # Defaults to `nil`. If this is falsy, `"ApplicationController"` is used. Can also be
    # configured on a per-test basis using `with_controller_class`.
    #

    # Set if render monkey patches should be included or not in Rails <6.1:
    #
    # ```ruby
    # config.view_component.render_monkey_patch_enabled = false
    # ```
    #

    # Path for component files
    #
    # ```ruby
    # config.view_component.view_component_path = "app/my_components"
    # ```
    #
    # Defaults to `nil`. If this is falsy, `app/components` is used.
    #

    # Evaluate `#content` before `#call` to ensure side-effects are present
    # during component renders. This will be the default behavior in a future
    # release.
    #
    # ```ruby
    # config.view_component.use_consistent_rendering_lifecycle = true
    # ```
    #
    # Defaults to `false`
    #
    mattr_accessor :use_consistent_rendering_lifecycle, instance_writer: false, default: false

    # Parent class for generated components
    #
    # ```ruby
    # config.view_component.component_parent_class = "MyBaseComponent"
    # ```
    #
    # Defaults to nil. If this is falsy, generators will use
    # "ApplicationComponent" if defined, "ViewComponent::Base" otherwise.
    #

    # Configuration for generators.
    #
    # All options under this namespace default to `false` unless otherwise
    # stated.
    #
    # #### #sidecar
    #
    # Always generate a component with a sidecar directory:
    #
    # ```ruby
    # config.view_component.generate.sidecar = true
    # ```
    #
    # #### #stimulus_controller
    #
    # Always generate a Stimulus controller alongside the component:
    #
    # ```ruby
    # config.view_component.generate.stimulus_controller = true
    # ```
    #
    # #### #locale
    #
    # Always generate translations file alongside the component:
    #
    # ```ruby
    # config.view_component.generate.locale = true
    # ```
    #
    # #### #distinct_locale_files
    #
    # Always generate as many translations files as available locales:
    #
    # ```ruby
    # config.view_component.generate.distinct_locale_files = true
    # ```
    #
    # One file will be generated for each configured `I18n.available_locales`,
    # falling back to `[:en]` when no `available_locales` is defined.
    #
    # #### #preview
    #
    # Always generate preview alongside the component:
    #
    # ```ruby
    # config.view_component.generate.preview = true
    # ```
    #
    #  Defaults to `false`.

    class << self
      # @private
      attr_accessor :source_location, :virtual_path

      # Find sidecar files for the given extensions.
      #
      # The provided array of extensions is expected to contain
      # strings starting without the "dot", example: `["erb", "haml"]`.
      #
      # For example, one might collect sidecar CSS files that need to be compiled.
      # @param extensions [Array<String>] Extensions of which to return matching sidecar files.
      def sidecar_files(extensions)
        return [] unless source_location

        extensions = extensions.join(",")

        # view files in a directory named like the component
        directory = File.dirname(source_location)
        filename = File.basename(source_location, ".rb")
        component_name = name.demodulize.underscore

        # Add support for nested components defined in the same file.
        #
        # for example
        #
        # class MyComponent < ViewComponent::Base
        #   class MyOtherComponent < ViewComponent::Base
        #   end
        # end
        #
        # Without this, `MyOtherComponent` will not look for `my_component/my_other_component.html.erb`
        nested_component_files =
          if name.include?("::") && component_name != filename
            Dir["#{directory}/#{filename}/#{component_name}.*{#{extensions}}"]
          else
            []
          end

        # view files in the same directory as the component
        sidecar_files = Dir["#{directory}/#{component_name}.*{#{extensions}}"]

        sidecar_directory_files = Dir["#{directory}/#{component_name}/#{filename}.*{#{extensions}}"]

        (sidecar_files - [source_location] + sidecar_directory_files + nested_component_files).uniq
      end

      # Render a component for each element in a collection ([documentation](/guide/collections)):
      #
      # ```ruby
      # render(ProductsComponent.with_collection(@products, foo: :bar))
      # ```
      #
      # @param collection [Enumerable] A list of items to pass the ViewComponent one at a time.
      # @param args [Arguments] Arguments to pass to the ViewComponent every time.
      def with_collection(collection, **args)
        Collection.new(self, collection, **args)
      end

      # Provide identifier for ActionView template annotations
      #
      # @private
      def short_identifier
        @short_identifier ||= defined?(Rails.root) ? source_location.sub("#{Rails.root}/", "") : source_location
      end

      # @private
      def inherited(child)
        # Compile so child will inherit compiled `call_*` template methods that
        # `compile` defines
        compile

        # Give the child its own personal #render_template_for to protect against the case when
        # eager loading is disabled and the parent component is rendered before the child. In
        # such a scenario, the parent will override ViewComponent::Base#render_template_for,
        # meaning it will not be called for any children and thus not compile their templates.
        if !child.instance_methods(false).include?(:render_template_for) && !child.compiled?
          child.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def render_template_for(variant = nil)
              # Force compilation here so the compiler always redefines render_template_for.
              # This is mostly a safeguard to prevent infinite recursion.
              self.class.compile(raise_errors: true, force: true)
              # .compile replaces this method; call the new one
              render_template_for(variant)
            end
          RUBY
        end

        # If Rails application is loaded, add application url_helpers to the component context
        # we need to check this to use this gem as a dependency
        if defined?(Rails) && Rails.application && !(child < Rails.application.routes.url_helpers)
          child.include Rails.application.routes.url_helpers
        end

        # Derive the source location of the component Ruby file from the call stack.
        # We need to ignore `inherited` frames here as they indicate that `inherited`
        # has been re-defined by the consuming application, likely in ApplicationComponent.
        child.source_location = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].path

        # Removes the first part of the path and the extension.
        child.virtual_path = child.source_location.gsub(
          /(.*#{Regexp.quote(ViewComponent::Base.config.view_component_path)})|(\.rb)/, ""
        )

        # Set collection parameter to the extended component
        child.with_collection_parameter provided_collection_parameter

        super
      end

      # @private
      def compiled?
        compiler.compiled?
      end

      # Compile templates to instance methods, assuming they haven't been compiled already.
      #
      # Do as much work as possible in this step, as doing so reduces the amount
      # of work done each time a component is rendered.
      # @private
      def compile(raise_errors: false, force: false)
        compiler.compile(raise_errors: raise_errors, force: force)
      end

      # @private
      def compiler
        @__vc_compiler ||= Compiler.new(self)
      end

      # we'll eventually want to update this to support other types
      # @private
      def type
        "text/html"
      end

      # @private
      def format
        :html
      end

      # @private
      def identifier
        source_location
      end

      # Set the parameter name used when rendering elements of a collection ([documentation](/guide/collections)):
      #
      # ```ruby
      # with_collection_parameter :item
      # ```
      #
      # @param parameter [Symbol] The parameter name used when rendering elements of a collection.
      def with_collection_parameter(parameter)
        @provided_collection_parameter = parameter
      end

      # Strips trailing whitespace from templates before compiling them.
      #
      # ```ruby
      # class MyComponent < ViewComponent::Base
      #   strip_trailing_whitespace
      # end
      # ```
      #
      # @param value [Boolean] Whether or not to strip newlines.
      def strip_trailing_whitespace(value = true)
        self.__vc_strip_trailing_whitespace = value
      end

      # Whether trailing whitespace will be stripped before compilation.
      #
      # @return [Boolean]
      def strip_trailing_whitespace?
        __vc_strip_trailing_whitespace
      end

      # Ensure the component initializer accepts the
      # collection parameter. By default, we don't
      # validate that the default parameter name
      # is accepted, as support for collection
      # rendering is optional.
      # @private TODO: add documentation
      def validate_collection_parameter!(validate_default: false)
        parameter = validate_default ? collection_parameter : provided_collection_parameter

        return unless parameter
        return if initialize_parameter_names.include?(parameter)

        # If Ruby can't parse the component class, then the initalize
        # parameters will be empty and ViewComponent will not be able to render
        # the component.
        if initialize_parameters.empty?
          raise ArgumentError, "The #{self} initializer is empty or invalid." \
            "It must accept the parameter `#{parameter}` to render it as a collection.\n\n" \
            "To fix this issue, update the initializer to accept `#{parameter}`.\n\n" \
            "See https://viewcomponent.org/guide/collections.html for more information on rendering collections."
        end

        raise ArgumentError, "The initializer for #{self} doesn't accept the parameter `#{parameter}`, " \
          "which is required in order to render it as a collection.\n\n" \
          "To fix this issue, update the initializer to accept `#{parameter}`.\n\n" \
          "See https://viewcomponent.org/guide/collections.html for more information on rendering collections."
      end

      # Ensure the component initializer doesn't define
      # invalid parameters that could override the framework's
      # methods.
      # @private TODO: add documentation
      def validate_initialization_parameters!
        return unless initialize_parameter_names.include?(RESERVED_PARAMETER)

        raise ViewComponent::ComponentError, "#{self} initializer can't accept the parameter `#{RESERVED_PARAMETER}`, as it will override a " \
          "public ViewComponent method. To fix this issue, rename the parameter."
      end

      # @private
      def collection_parameter
        provided_collection_parameter || name && name.demodulize.underscore.chomp("_component").to_sym
      end

      # @private
      def collection_counter_parameter
        "#{collection_parameter}_counter".to_sym
      end

      # @private
      def counter_argument_present?
        initialize_parameter_names.include?(collection_counter_parameter)
      end

      # @private
      def collection_iteration_parameter
        "#{collection_parameter}_iteration".to_sym
      end

      # @private
      def iteration_argument_present?
        initialize_parameter_names.include?(collection_iteration_parameter)
      end

      private

      def initialize_parameter_names
        return attribute_names.map(&:to_sym) if respond_to?(:attribute_names)

        return attribute_types.keys.map(&:to_sym) if Rails::VERSION::MAJOR <= 5 && respond_to?(:attribute_types)

        initialize_parameters.map(&:last)
      end

      def initialize_parameters
        instance_method(:initialize).parameters
      end

      def provided_collection_parameter
        @provided_collection_parameter ||= nil
      end
    end

    ActiveSupport.run_load_hooks(:view_component, self)
  end
end
