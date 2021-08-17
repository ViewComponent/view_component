# frozen_string_literal: true

require "action_view"
require "active_support/configurable"
require "view_component/collection"
require "view_component/compile_cache"
require "view_component/content_areas"
require "view_component/previewable"
require "view_component/slotable"
require "view_component/slotable_v2"
require "view_component/with_content_helper"

module ViewComponent
  class Base < ActionView::Base
    include ActiveSupport::Configurable
    include ViewComponent::ContentAreas
    include ViewComponent::Previewable
    include ViewComponent::SlotableV2
    include ViewComponent::WithContentHelper

    ViewContextCalledBeforeRenderError = Class.new(StandardError)

    RESERVED_PARAMETER = :content

    # For CSRF authenticity tokens in forms
    delegate :form_authenticity_token, :protect_against_forgery?, :config, to: :helpers

    class_attribute :content_areas
    self.content_areas = [] # class_attribute:default doesn't work until Rails 5.2

    # EXPERIMENTAL: This API is experimental and may be removed at any time.
    # Hook for allowing components to do work as part of the compilation process.
    #
    # For example, one might compile component-specific assets at this point.
    # @private TODO: add documentation
    def self._after_compile
      # noop
    end

    # Entrypoint for rendering components.
    #
    # view_context: ActionView context from calling view
    # block: optional block to be captured within the view context
    #
    # returns HTML that has been escaped by the respective template handler
    #
    # Example subclass:
    #
    # app/components/my_component.rb:
    # class MyComponent < ViewComponent::Base
    #   def initialize(title:)
    #     @title = title
    #   end
    # end
    #
    # app/components/my_component.html.erb
    # <span title="<%= @title %>">Hello, <%= content %>!</span>
    #
    # In use:
    # <%= render MyComponent.new(title: "greeting") do %>world<% end %>
    # returns:
    # <span title="greeting">Hello, world!</span>
    #
    # @private
    def render_in(view_context, &block)
      self.class.compile(raise_errors: true)

      @view_context = view_context
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
        raise ArgumentError.new(
          "It looks like a block was provided after calling `with_content` on #{self.class.name}, " \
          "which means that ViewComponent doesn't know which content to use.\n\n" \
          "To fix this issue, use either `with_content` or a block."
        )
      end

      @__vc_content_evaluated = false
      @__vc_render_in_block = block

      before_render

      if render?
        render_template_for(@__vc_variant).to_s + _output_postamble
      else
        ""
      end
    ensure
      @current_template = old_current_template
    end

    # EXPERIMENTAL: Optional content to be returned after the rendered template.
    #
    # @return [String]
    def _output_postamble
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
    def initialize(*); end

    # Re-use original view_context if we're not rendering a component.
    #
    # This prevents an exception when rendering a partial inside of a component that has also been rendered outside
    # of the component. This is due to the partials compiled template method existing in the parent `view_context`,
    #  and not the component's `view_context`.
    #
    # @private
    def render(options = {}, args = {}, &block)
      if options.is_a? ViewComponent::Base
        super
      else
        view_context.render(options, args, &block)
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
          "`#controller` cannot be used during initialization, as it depends " \
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
          "`#helpers` cannot be used during initialization, as it depends " \
          "on the view context that only exists once a ViewComponent is passed to " \
          "the Rails render pipeline.\n\n" \
          "It's sometimes possible to fix this issue by moving code dependent on " \
          "`#helpers` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."
        )
      end

      @__vc_helpers ||= controller.view_context
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
      # Ruby 2.6 throws a warning without checking `defined?`, 2.7 does not
      if defined?(@__vc_variant)
        @__vc_variant
      end
    end

    # Use the provided variant instead of the one determined by the current request.
    #
    # @deprecated Will be removed in v3.0.0.
    # @param variant [Symbol] The variant to be used by the component.
    # @return [self]
    def with_variant(variant)
      ActiveSupport::Deprecation.warn(
        "`with_variant` is deprecated and will be removed in ViewComponent v3.0.0."
      )

      @__vc_variant = variant

      self
    end

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
    #     config.view_component.test_controller = "MyTestController"
    #
    # Defaults to ApplicationController. Can also be configured on a per-test
    # basis using `with_controller_class`.
    #
    mattr_accessor :test_controller
    @@test_controller = "ApplicationController"

    # Set if render monkey patches should be included or not in Rails <6.1:
    #
    #     config.view_component.render_monkey_patch_enabled = false
    #
    mattr_accessor :render_monkey_patch_enabled, instance_writer: false, default: true

    # Enable or disable source code previews in component previews:
    #
    #     config.view_component.show_previews_source = true
    #
    # Defaults to `false`.
    #
    mattr_accessor :show_previews_source, instance_writer: false, default: false

    # Always generate a Stimulus controller alongside the component:
    #
    #     config.view_component.generate_stimulus_controller = true
    #
    # Defaults to `false`.
    #
    mattr_accessor :generate_stimulus_controller, instance_writer: false, default: false

    # Path for component files
    #
    #     config.view_component.view_component_path = "app/my_components"
    #
    # Defaults to "app/components".
    mattr_accessor :view_component_path, instance_writer: false, default: "app/components"

    class << self
      # @private
      attr_accessor :source_location, :virtual_path

      # EXPERIMENTAL: This API is experimental and may be removed at any time.
      # Find sidecar files for the given extensions.
      #
      # The provided array of extensions is expected to contain
      # strings starting without the "dot", example: `["erb", "haml"]`.
      #
      # For example, one might collect sidecar CSS files that need to be compiled.
      # @private TODO: add documentation
      def _sidecar_files(extensions)
        return [] unless source_location

        extensions = extensions.join(",")

        # view files in a directory named like the component
        directory = File.dirname(source_location)
        filename = File.basename(source_location, ".rb")
        component_name = name.demodulize.underscore

        # Add support for nested components defined in the same file.
        #
        # e.g.
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
      #     render(ProductsComponent.with_collection(@products, foo: :bar))
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

        # If Rails application is loaded, add application url_helpers to the component context
        # we need to check this to use this gem as a dependency
        if defined?(Rails) && Rails.application
          child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers
        end

        # Derive the source location of the component Ruby file from the call stack.
        # We need to ignore `inherited` frames here as they indicate that `inherited`
        # has been re-defined by the consuming application, likely in ApplicationComponent.
        child.source_location = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].absolute_path

        # Removes the first part of the path and the extension.
        child.virtual_path = child.source_location.gsub(
          %r{(.*#{Regexp.quote(ViewComponent::Base.view_component_path)})|(\.rb)}, ""
        )

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
      def compile(raise_errors: false)
        compiler.compile(raise_errors: raise_errors)
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
      #     with_collection_parameter :item
      #
      # @param parameter [Symbol] The parameter name used when rendering elements of a collection.
      def with_collection_parameter(parameter)
        @provided_collection_parameter = parameter
      end

      # Ensure the component initializer accepts the
      # collection parameter. By default, we do not
      # validate that the default parameter name
      # is accepted, as support for collection
      # rendering is optional.
      # @private TODO: add documentation
      def validate_collection_parameter!(validate_default: false)
        parameter = validate_default ? collection_parameter : provided_collection_parameter

        return unless parameter
        return if initialize_parameter_names.include?(parameter)

        # If Ruby cannot parse the component class, then the initalize
        # parameters will be empty and ViewComponent will not be able to render
        # the component.
        if initialize_parameters.empty?
          raise ArgumentError.new(
            "The #{self} initializer is empty or invalid." \
            "It must accept the parameter `#{parameter}` to render it as a collection.\n\n" \
            "To fix this issue, update the initializer to accept `#{parameter}`.\n\n" \
            "See https://viewcomponent.org/guide/collections.html for more information on rendering collections."
          )
        end

        raise ArgumentError.new(
          "The initializer for #{self} does not accept the parameter `#{parameter}`, " \
          "which is required in order to render it as a collection.\n\n" \
          "To fix this issue, update the initializer to accept `#{parameter}`.\n\n" \
          "See https://viewcomponent.org/guide/collections.html for more information on rendering collections."
        )
      end

      # Ensure the component initializer does not define
      # invalid parameters that could override the framework's
      # methods.
      # @private TODO: add documentation
      def validate_initialization_parameters!
        return unless initialize_parameter_names.include?(RESERVED_PARAMETER)

        raise ViewComponent::ComponentError.new(
          "#{self} initializer cannot accept the parameter `#{RESERVED_PARAMETER}`, as it will override a " \
          "public ViewComponent method. To fix this issue, rename the parameter."
        )
      end

      # @private
      def collection_parameter
        if provided_collection_parameter
          provided_collection_parameter
        else
          name && name.demodulize.underscore.chomp("_component").to_sym
        end
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
