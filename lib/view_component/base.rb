# frozen_string_literal: true

require "action_view"
require "active_support/configurable"
require "view_component/collection"
require "view_component/previewable"

module ViewComponent
  class Base < ActionView::Base
    include ActiveSupport::Configurable
    include ViewComponent::Previewable

    delegate :form_authenticity_token, :protect_against_forgery?, to: :helpers

    class_attribute :content_areas, default: []
    self.content_areas = [] # default doesn't work until Rails 5.2

    # Render a component collection.
    def self.with_collection(*args)
      Collection.new(self, *args)
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
    def render_in(view_context, &block)
      self.class.compile!
      @view_context = view_context
      @view_renderer ||= view_context.view_renderer
      @lookup_context ||= view_context.lookup_context
      @view_flow ||= view_context.view_flow
      @virtual_path ||= virtual_path
      @variant = @lookup_context.variants.first

      old_current_template = @current_template
      @current_template = self

      @content = view_context.capture(self, &block) if block_given?

      before_render_check

      if render?
        send(self.class.call_method_name(@variant))
      else
        ""
      end
    ensure
      @current_template = old_current_template
    end

    def before_render_check
      # noop
    end

    def render?
      true
    end

    def self.short_identifier
      @short_identifier ||= defined?(Rails.root) ? source_location.sub("#{Rails.root}/", "") : source_location
    end

    def initialize(*); end

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

    # Provides a proxy to access helper methods through
    def helpers
      @helpers ||= view_context
    end

    # Removes the first part of the path and the extension.
    def virtual_path
      self.class.source_location.gsub(%r{(.*app/components)|(\.rb)}, "")
    end

    def view_cache_dependencies
      []
    end

    def format # :nodoc:
      @variant
    end

    def with(area, content = nil, **attributes, &block)
      unless content_areas.include?(area)
        raise ArgumentError.new "Unknown content_area '#{area}' - expected one of '#{content_areas}'"
      end

      if block_given?
        content = view_context.capture(&block)
      end

      instance_variable_set("@#{area}".to_sym, content)
      instance_variable_set("@#{area}_attributes".to_sym, attributes)
      nil
    end

    private

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

      def inherited(child)
        if defined?(Rails)
          child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers
        end

        # Derive the source location of the component Ruby file from the call stack.
        # We need to ignore `inherited` frames here as they indicate that `inherited`
        # has been re-defined by the consuming application, likely in ApplicationComponent.
        child.source_location = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].absolute_path

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
        @compiled && ActionView::Base.cache_template_loading
      end

      def compile!
        compile(raise_template_errors: true)
      end

      # Compile templates to instance methods, assuming they haven't been compiled already.
      # We could in theory do this on app boot, at least in production environments.
      # Right now this just compiles the first time the component is rendered.
      def compile(raise_template_errors: false)
        return if compiled?

        if template_errors.present?
          raise ViewComponent::TemplateError.new(template_errors) if raise_template_errors
          return false
        end

        define_singleton_method(:variants) do
          templates.map { |template| template[:variant] } + variants_from_inline_calls(inline_calls)
        end

        define_singleton_method(:collection_counter_parameter_name) do
          "#{collection_parameter_name}_counter".to_sym
        end

        define_singleton_method(:counter_argument_present?) do
          instance_method(:initialize).parameters.map(&:second).include?(collection_counter_parameter_name)
        end

        # If template name annotations are turned on, a line is dynamically
        # added with a comment. In this case, we want to return a different
        # starting line number so errors that are raised will point to the
        # correct line in the component template.
        line_number =
          if ActionView::Base.respond_to?(:annotate_template_file_names) &&
            ActionView::Base.annotate_template_file_names
            -2
          else
            -1
          end

        templates.each do |template|
          class_eval <<-RUBY, template[:path], line_number
            def #{call_method_name(template[:variant])}
              @output_buffer = ActionView::OutputBuffer.new
              #{compiled_template(template[:path])}
            end
          RUBY
        end

        @compiled = true
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
        attr_reader *areas
        attr_reader *areas.map { |area| "#{area}_attributes" }
        self.content_areas = areas
      end

      # Support overriding this component's collection parameter name
      def with_collection_parameter(param)
        @with_collection_parameter = param
      end

      def collection_parameter_name
        (@with_collection_parameter || name.demodulize.underscore.chomp("_component")).to_sym
      end

      private

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
        (Dir["#{source_location.chomp(File.extname(source_location))}.*{#{ActionView::Template.template_handler_extensions.join(',')}}"] - [source_location])
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
