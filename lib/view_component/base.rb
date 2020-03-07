# frozen_string_literal: true

require "action_view"
require "active_support/configurable"
require "view_component/previewable"

module ViewComponent
  class Base < ActionView::Base
    include ActiveSupport::Configurable
    include ViewComponent::Previewable
    include ViewComponent::Rendering

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
      @view_flow ||= view_context.view_flow
      @variants = view_context.lookup_context.variants
      @view_context = view_context

      old_current_template = @current_template
      @current_template = self

      @content = view_context.capture(self, &block) if block_given?

      before_render_check

      if render?
        @details_for_lookup = { formats: %i[html], variants: @variants }
        template = lookup_context.find_template(self.class.template_name)
        template.render(self, {})
      else
        ""
      end
    ensure
      @current_template = old_current_template
    end

    def details_for_lookup
      @details_for_lookup || {}
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
      attr_reader :abstract
      alias_method :abstract?, :abstract

      # Define a component as abstract. See internal_methods for more
      # details.
      def abstract!
        @abstract = true
      end

      def inherited(child)
        child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers

        # Define the abstract ivar on subclasses so that we don't get
        # uninitialized ivar warnings
        unless child.instance_variable_defined?(:@abstract)
          child.instance_variable_set(:@abstract, false)
        end
        super
      end

      def component_path
        @component_path ||= name.underscore unless anonymous?
      end

      def template_name
        self.name.underscore
      end

      # TODO: use lookup_context formats
      # we'll eventually want to update this to support other types
      def type
        "text/html"
      end

      def with_content_areas(*areas)
        if areas.include?(:content)
          raise ArgumentError.new ":content is a reserved content area name. Please use another name, such as ':body'"
        end
        attr_reader *areas
        self.content_areas = areas
      end
    end

    abstract!

    ActiveSupport.run_load_hooks(:action_view_component, self)
  end
end
