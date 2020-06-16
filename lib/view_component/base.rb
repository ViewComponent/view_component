# frozen_string_literal: true

require "action_view"
require "active_support/configurable"
require "view_component/collection"
require "view_component/compile_cache"
require "view_component/previewable"
require "view_component/slot"

module ViewComponent
  class Base < ActionView::Base
    include ActiveSupport::Configurable
    include ViewComponent::Previewable

    # For CSRF authenticity tokens in forms
    delegate :form_authenticity_token, :protect_against_forgery?, :config, to: :helpers

    class_attribute :content_areas
    self.content_areas = [] # class_attribute:default doesn't work until Rails 5.2

    # Hash of registered Slots
    class_attribute :slots
    self.slots = {}

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
      @variant = @lookup_context.variants.first

      # For caching, such as #cache_if
      @current_template = nil unless defined?(@current_template)
      old_current_template = @current_template
      @current_template = self

      # Assign captured content passed to component as a block to @content
      @content = view_context.capture(self, &block) if block_given?

      before_render

      if render?
        send(self.class.call_method_name(@variant))
      else
        ""
      end
    ensure
      @current_template = old_current_template
    end

    def before_render
      before_render_check
    end

    def before_render_check
      # noop
    end

    def render?
      true
    end

    def initialize(*); end

    # If trying to render a partial or template inside a component,
    # pass the render call to the parent view_context.
    def render(options = {}, args = {}, &block)
      if options.is_a?(String) || (options.is_a?(Hash) && options.has_key?(:partial))
        view_context.render(options, args, &block)
      else
        super
      end
    end

    def controller
      @controller ||= view_context.controller
    end

    # Provides a proxy to access helper methods from the context of the current controller
    def helpers
      @helpers ||= controller.view_context
    end

    # Removes the first part of the path and the extension.
    def virtual_path
      self.class.source_location.gsub(%r{(.*app/components)|(\.rb)}, "")
    end

    # For caching, such as #cache_if
    def view_cache_dependencies
      []
    end

    # For caching, such as #cache_if
    def format
      @variant
    end

    # Assign the provided content to the content area accessor
    def with(area, content = nil, &block)
      unless content_areas.include?(area)
        raise ArgumentError.new "Unknown content_area '#{area}' - expected one of '#{content_areas}'"
      end

      if block_given?
        content = view_context.capture(&block)
      end

      instance_variable_set("@#{area}".to_sym, content)
      nil
    end

    # Build a Slot instance on a component,
    # exposing it for use inside the
    # component template.
    #
    # slot: Name of Slot, in symbol form
    # **args: Arguments to be passed to Slot initializer
    #
    # For example:
    # <%= render(SlotsComponent.new) do |component| %>
    #   <% component.slot(:footer, class_names: "footer-class") do %>
    #     <p>This is my footer!</p>
    #   <% end %>
    # <% end %>
    #
    def slot(slot_name, **args, &block)
      # Raise ArgumentError if `slot` does not exist
      unless slots.keys.include?(slot_name)
        raise ArgumentError.new "Unknown slot '#{slot_name}' - expected one of '#{slots.keys}'"
      end

      slot = slots[slot_name]

      # The class name of the Slot, such as Header
      slot_class = self.class.const_get(slot[:class_name])

      # Instantiate Slot class, accommodating Slots that don't accept arguments
      slot_instance = args.present? ? slot_class.new(args) : slot_class.new

      # Capture block and assign to slot_instance#content
      slot_instance.content = view_context.capture(&block) if block_given?

      if slot[:collection]
        # Initialize instance variable as an empty array
        # if slot is a collection and has yet to be initialized
        unless instance_variable_defined?(slot[:instance_variable_name])
          instance_variable_set(slot[:instance_variable_name], [])
        end

        # Append Slot instance to collection accessor Array
        instance_variable_get(slot[:instance_variable_name]) << slot_instance
      else
         # Assign the Slot instance to the slot accessor
        instance_variable_set(slot[:instance_variable_name], slot_instance)
      end

      # Return nil, as this method should not output anything to the view itself.
      nil
    end

    private

    # Exposes the current request to the component.
    # Use sparingly as doing so introduces coupling
    # that inhibits encapsulation & reuse.
    def request
      @request ||= controller.request
    end

    attr_reader :content, :view_context

    # The controller used for testing components.
    # Defaults to ApplicationController. This should be set early
    # in the initialization process and should be set to a string.
    mattr_accessor :test_controller
    @@test_controller = "ApplicationController"

    class << self
      attr_accessor :source_location

      # Render a component collection.
      def with_collection(*args)
        Collection.new(self, *args)
      end

      # Provide identifier for ActionView template annotations
      def short_identifier
        @short_identifier ||= defined?(Rails.root) ? source_location.sub("#{Rails.root}/", "") : source_location
      end

      def inherited(child)
        # If we're in Rails, add application url_helpers to the component context
        if defined?(Rails)
          child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers
        end

        # Derive the source location of the component Ruby file from the call stack.
        # We need to ignore `inherited` frames here as they indicate that `inherited`
        # has been re-defined by the consuming application, likely in ApplicationComponent.
        child.source_location = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].absolute_path

        # Clone slot configuration into child class
        # see #test_slots_pollution
        child.slots = self.slots.clone

        super
      end

      def call_method_name(variant)
        if variant.present? && variants.include?(variant)
          "call_#{variant}"
        else
          "call"
        end
      end

      def compiled?
        CompileCache.compiled?(self)
      end

      # Compile templates to instance methods, assuming they haven't been compiled already.
      #
      # Do as much work as possible in this step, as doing so reduces the amount
      # of work done each time a component is rendered.
      def compile(raise_errors: false)
        return if compiled?

        if template_errors.present?
          raise ViewComponent::TemplateError.new(template_errors) if raise_errors
          return false
        end

        if instance_methods(false).include?(:before_render_check)
          ActiveSupport::Deprecation.warn(
            "`before_render_check` will be removed in v3.0.0. Use `before_render` instead."
          )
        end

        # Remove any existing singleton methods,
        # as Ruby warns when redefining a method.
        remove_possible_singleton_method(:variants)
        remove_possible_singleton_method(:collection_parameter)
        remove_possible_singleton_method(:collection_counter_parameter)
        remove_possible_singleton_method(:counter_argument_present?)

        define_singleton_method(:variants) do
          templates.map { |template| template[:variant] } + variants_from_inline_calls(inline_calls)
        end

        define_singleton_method(:collection_parameter) do
          if provided_collection_parameter
            provided_collection_parameter
          else
            name.demodulize.underscore.chomp("_component").to_sym
          end
        end

        define_singleton_method(:collection_counter_parameter) do
          "#{collection_parameter}_counter".to_sym
        end

        define_singleton_method(:counter_argument_present?) do
          instance_method(:initialize).parameters.map(&:second).include?(collection_counter_parameter)
        end

        validate_collection_parameter! if raise_errors

        # If template name annotations are turned on, a line is dynamically
        # added with a comment. In this case, we want to return a different
        # starting line number so errors that are raised will point to the
        # correct line in the component template.
        line_number =
          if ActionView::Base.respond_to?(:annotate_rendered_view_with_filenames) &&
            ActionView::Base.annotate_rendered_view_with_filenames
            -2
          else
            -1
          end

        templates.each do |template|
          # Remove existing compiled template methods,
          # as Ruby warns when redefining a method.
          method_name = call_method_name(template[:variant])
          undef_method(method_name.to_sym) if instance_methods.include?(method_name.to_sym)

          class_eval <<-RUBY, template[:path], line_number
            def #{method_name}
              @output_buffer = ActionView::OutputBuffer.new
              #{compiled_template(template[:path])}
            end
          RUBY
        end

        CompileCache.register self
      end

      # we'll eventually want to update this to support other types
      def type
        "text/html"
      end

      def format
        :html
      end

      def identifier
        source_location
      end

      def with_content_areas(*areas)
        if areas.include?(:content)
          raise ArgumentError.new ":content is a reserved content area name. Please use another name, such as ':body'"
        end
        attr_reader(*areas)
        self.content_areas = areas
      end

      # support initalizing slots as:
      #
      # with_slot(
      #   :header,
      #   collection: true|false,
      #   class_name: "Header" # class name string, used to instantiate Slot
      # )
      def with_slot(*slot_names, collection: false, class_name: nil)
        slot_names.each do |slot_name|
          # Ensure slot_name is not already declared
          if self.slots.key?(slot_name)
            raise ArgumentError.new("#{slot_name} slot declared multiple times")
          end

          # Ensure slot name is not :content
          if slot_name == :content
            raise ArgumentError.new ":content is a reserved slot name. Please use another name, such as ':body'"
          end

          # Set the name of the method used to access the Slot(s)
          accessor_name =
            if collection
              # If Slot is a collection, set the accessor
              # name to the pluralized form of the slot name
              # For example: :tab => :tabs
              ActiveSupport::Inflector.pluralize(slot_name)
            else
              slot_name
            end

          instance_variable_name = "@#{accessor_name}"

          # If the slot is a collection, define an accesor that defaults to an empty array
          if collection
            class_eval <<-RUBY
              def #{accessor_name}
                #{instance_variable_name} ||= []
              end
            RUBY
          else
            attr_reader accessor_name
          end

          # Generate a Slot class unless one is provided.
          # `with_slot(:header)` generates MyComponent::Header < ViewComponent::Slot
          unless class_name.present?
            self.const_set(slot_name.to_s.capitalize, Class.new(ViewComponent::Slot))
            class_name = "#{self}::#{slot_name.to_s.capitalize}"
          end

          # Register the slot on the component
          self.slots[slot_name] = {
            class_name: class_name,
            instance_variable_name: instance_variable_name,
            collection: collection
          }
        end
      end

      # Support overriding collection parameter name
      def with_collection_parameter(param)
        @provided_collection_parameter = param
      end

      # Ensure the component initializer accepts the
      # collection parameter. By default, we do not
      # validate that the default parameter name
      # is accepted, as support for collection
      # rendering is optional.
      def validate_collection_parameter!(validate_default: false)
        parameter = validate_default ? collection_parameter : provided_collection_parameter

        return unless parameter
        return if initialize_parameters.map(&:last).include?(parameter)

        # If Ruby cannot parse the component class, then the initalize
        # parameters will be empty and ViewComponent will not be able to render
        # the component.
        if initialize_parameters.empty?
          raise ArgumentError.new(
            "#{self} initializer is empty or invalid."
          )
        end

        raise ArgumentError.new(
          "#{self} initializer must accept " \
          "`#{parameter}` collection parameter."
        )
      end

      private

      def initialize_parameters
        instance_method(:initialize).parameters
      end

      def provided_collection_parameter
        @provided_collection_parameter ||= nil
      end

      def compiled_template(file_path)
        handler = ActionView::Template.handler_for_extension(File.extname(file_path).gsub(".", ""))
        template = File.read(file_path)

        if handler.method(:call).parameters.length > 1
          handler.call(self, template)
        else
          handler.call(OpenStruct.new(source: template, identifier: identifier, type: type))
        end
      end

      def inline_calls
        @inline_calls ||=
          begin
            # Fetch only ViewComponent ancestor classes to limit the scope of
            # finding inline calls
            view_component_ancestors =
              ancestors.take_while { |ancestor| ancestor != ViewComponent::Base } - included_modules

            view_component_ancestors.flat_map { |ancestor| ancestor.instance_methods(false).grep(/^call/) }.uniq
          end
      end

      def inline_calls_defined_on_self
        @inline_calls_defined_on_self ||= instance_methods(false).grep(/^call/)
      end

      def matching_views_in_source_location
        return [] unless source_location

        location_without_extension = source_location.chomp(File.extname(source_location))

        extenstions = ActionView::Template.template_handler_extensions.join(",")

        # view files in the same directory as te component
        sidecar_files = Dir["#{location_without_extension}.*{#{extenstions}}"]

        # view files in a directory named like the component
        directory = File.dirname(source_location)
        filename = File.basename(source_location, ".rb")
        component_name = name.demodulize.underscore

        sidecar_directory_files = Dir["#{directory}/#{component_name}/#{filename}.*{#{extenstions}}"]

        (sidecar_files - [source_location] + sidecar_directory_files)
      end

      def templates
        @templates ||=
          matching_views_in_source_location.each_with_object([]) do |path, memo|
            pieces = File.basename(path).split(".")

            memo << {
              path: path,
              variant: pieces.second.split("+").second&.to_sym,
              handler: pieces.last
            }
          end
      end

      def template_errors
        @template_errors ||=
          begin
            errors = []

            if (templates + inline_calls).empty?
              errors << "Could not find a template file or inline render method for #{self}."
            end

            if templates.count { |template| template[:variant].nil? } > 1
              errors << "More than one template found for #{self}. There can only be one default template file per component."
            end

            invalid_variants = templates
                                  .group_by { |template| template[:variant] }
                                  .map { |variant, grouped| variant if grouped.length > 1 }
                                  .compact
                                  .sort

            unless invalid_variants.empty?
              errors << "More than one template found for #{'variant'.pluralize(invalid_variants.count)} #{invalid_variants.map { |v| "'#{v}'" }.to_sentence} in #{self}. There can only be one template file per variant."
            end

            if templates.find { |template| template[:variant].nil? } && inline_calls_defined_on_self.include?(:call)
              errors << "Template file and inline render method found for #{self}. There can only be a template file or inline render method per component."
            end

            duplicate_template_file_and_inline_variant_calls =
              templates.pluck(:variant) & variants_from_inline_calls(inline_calls_defined_on_self)

            unless duplicate_template_file_and_inline_variant_calls.empty?
              count = duplicate_template_file_and_inline_variant_calls.count

              errors << "Template #{'file'.pluralize(count)} and inline render #{'method'.pluralize(count)} found for #{'variant'.pluralize(count)} #{duplicate_template_file_and_inline_variant_calls.map { |v| "'#{v}'" }.to_sentence} in #{self}. There can only be a template file or inline render method per variant."
            end

            errors
          end
      end

      def variants_from_inline_calls(calls)
        calls.reject { |call| call == :call }.map do |variant_call|
          variant_call.to_s.sub("call_", "").to_sym
        end
      end
    end

    ActiveSupport.run_load_hooks(:view_component, self)
  end
end
