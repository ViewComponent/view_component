# frozen_string_literal: true

require "action_view"
require "active_support/configurable"
require "view_component/previewable"

module ViewComponent
  class Base < ActionView::Base
    include ActiveSupport::Configurable
    include ViewComponent::Previewable

    delegate :form_authenticity_token, :protect_against_forgery?, to: :helpers

    class_attribute :content_areas, default: []
    self.content_areas = [] # default doesn't work until Rails 5.2

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
      def inherited(child)
        if defined?(Rails)
          child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers
        end

        super
      end

      def call_method_name(variant)
        if variant.present? && variants.include?(variant)
          "call_#{variant}"
        else
          "call"
        end
      end

      def source_location
        @source_location ||=
          begin
            # Require `#initialize` to be defined so that we can use `method#source_location`
            # to look up the filename of the component.
            initialize_method = instance_method(:initialize)
            initialize_method.source_location[0] if initialize_method.owner == self
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

        templates.each do |template|
          class_eval <<-RUBY, template[:path], -1
            def #{call_method_name(template[:variant])}
              @output_buffer = ActionView::OutputBuffer.new
              #{compiled_template(template[:path])}
            end
          RUBY
        end

        @compiled = true
      end

      def variants
        templates.map { |template| template[:variant] }
      end

      # we'll eventually want to update this to support other types
      def type
        "text/html"
      end

      def identifier
        source_location
      end

      def with_content_areas(*areas)
        if areas.include?(:content)
          raise ArgumentError.new ":content is a reserved content area name. Please use another name, such as ':body'"
        end
        attr_reader *areas
        self.content_areas = areas
      end

      private

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
            if source_location.nil?
              # Require `#initialize` to be defined so that we can use `method#source_location`
              # to look up the filename of the component.
              errors << "#{self} must implement #initialize."
            end

            errors << "Could not find a template file for #{self}." if templates.empty?

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
            errors
          end
      end

      def compiled_template(file_path)
        handler = ActionView::Template.handler_for_extension(File.extname(file_path).gsub(".", ""))
        template = File.read(file_path)

        if handler.method(:call).parameters.length > 1
          handler.call(self, template)
        else # remove before upstreaming into Rails
          handler.call(OpenStruct.new(source: template, identifier: identifier, type: type))
        end
      end
    end

    ActiveSupport.run_load_hooks(:action_view_component, self)
  end
end
