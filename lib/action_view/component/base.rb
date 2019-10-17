# frozen_string_literal: true

# Monkey patch ActionView::Base#render to support ActionView::Component
#
# A version of this monkey patch was upstreamed in https://github.com/rails/rails/pull/36388
# We'll need to upstream an updated version of this eventually.
class ActionView::Base
  module RenderMonkeyPatch
    def render(options = {}, args = {}, &block)
      if options.respond_to?(:render_in)
        ActiveSupport::Deprecation.warn(
          "passing component instances to `render` has been deprecated and will be removed in v2.0.0. Use `render MyComponent, foo: :bar` instead."
        )

        options.render_in(self, &block)
      elsif options.is_a?(Class) && options < ActionView::Component::Base
        options.new(args).render_in(self, &block)
      elsif options.is_a?(Hash) && options.has_key?(:component)
        options[:component].new(options[:locals]).render_in(self, &block)
      else
        super
      end
    end
  end

  prepend RenderMonkeyPatch
end

module ActionView
  module Component
    class Base < ActionView::Base
      include ActiveModel::Validations
      include ActiveSupport::Configurable
      include ActionController::RequestForgeryProtection

      # Entrypoint for rendering components. Called by ActionView::Base#render.
      #
      # view_context: ActionView context from calling view
      # args(hash): params to be passed to component being rendered
      # block: optional block to be captured within the view context
      #
      # returns HTML that has been escaped by the respective template handler
      #
      # Example subclass:
      #
      # app/components/my_component.rb:
      # class MyComponent < ActionView::Component::Base
      #   def initialize(title:)
      #     @title = title
      #   end
      # end
      #
      # app/components/my_component.html.erb
      # <span title="<%= @title %>">Hello, <%= content %>!</span>
      #
      # In use:
      # <%= render MyComponent, title: "greeting" do %>world<% end %>
      # returns:
      # <span title="greeting">Hello, world!</span>
      #
      def render_in(view_context, *args, &block)
        self.class.compile
        @view_context = view_context
        @view_renderer ||= view_context.view_renderer
        @lookup_context ||= view_context.lookup_context
        @view_flow ||= view_context.view_flow

        @content = view_context.capture(&block) if block_given?
        validate!
        call
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

      class << self
        def inherited(child)
          child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers

          super
        end

        # Compile template to #call instance method, assuming it hasn't been compiled already.
        # We could in theory do this on app boot, at least in production environments.
        # Right now this just compiles the template the first time the component is rendered.
        def compile
          return if @compiled && ActionView::Base.cache_template_loading

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def call
              @output_buffer = ActionView::OutputBuffer.new
              #{compiled_template}
            end
          RUBY

          @compiled = true
        end

        private

        def compiled_template
          handler = ActionView::Template.handler_for_extension(File.extname(template_file_path).gsub(".", ""))
          template = File.read(template_file_path)

          if handler.method(:call).parameters.length > 1
            handler.call(DummyTemplate.new, template)
          else
            handler.call(DummyTemplate.new(template))
          end
        end

        def template_file_path
          raise NotImplementedError.new("#{self} must implement #initialize.") unless self.instance_method(:initialize).owner == self

          filename = self.instance_method(:initialize).source_location[0]
          filename_without_extension = filename[0..-(File.extname(filename).length + 1)]
          sibling_template_files = file_path_array(filename_without_extension) - [filename]
          sibling_template_files = file_path_array(Rails.root.join("app", "views", "components", File.basename(filename, ".*")).to_s) if sibling_template_files.blank?

          if sibling_template_files.length > 1
            raise StandardError.new("More than one template found for #{self}. There can only be one sidecar template file per component.")
          end

          if sibling_template_files.length == 0
            raise NotImplementedError.new(
              "Could not find a template file for #{self}."
            )
          end

          sibling_template_files[0]
        end

        def file_path_array(filename)
          Dir["#{filename}.????.{#{ActionView::Template.template_handler_extensions.join(',')}}"]
        end
        
      end

      class DummyTemplate
        attr_reader :source

        def initialize(source = nil)
          @source = source
        end

        def identifier
          ""
        end

        # we'll eventually want to update this to support other types
        def type
          "text/html"
        end
      end

      private

      def request
        @request ||= controller.request
      end

      attr_reader :content, :view_context
    end
  end
end
