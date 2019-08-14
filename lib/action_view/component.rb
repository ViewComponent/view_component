# frozen_string_literal: true

# Monkey patch ActionView::Base#render to support ActionView::Component
#
# Upstreamed in https://github.com/rails/rails/pull/36388
# Necessary for Rails versions < 6.1.0.alpha
class ActionView::Base
  module RenderMonkeyPatch
    def render(component, _ = nil, &block)
      return super unless component.respond_to?(:render_in)

      component.render_in(self, &block)
    end
  end

  prepend RenderMonkeyPatch unless Rails::VERSION::MINOR > 0 && Rails::VERSION::MAJOR == 6
end

module ActionView
  class Component < ActionView::Base
    VERSION = "0.2.0"

    include ActiveModel::Validations

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
    # class MyComponent < ActionView::Component
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
    def render_in(view_context, *args, &block)
      self.class.compile
      @content = view_context.capture(&block) if block_given?
      validate!
      call
    end

    def initialize(*); end

    class << self
      def inherited(child)
        child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers

        super
      end

      # Compile template to #call instance method, assuming it hasn't been compiled already
      def compile
        return if @compiled

        class_eval("def call; @output_buffer = ActionView::OutputBuffer.new; #{compiled_template}; end")

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
        sibling_files = Dir["#{filename_without_extension}.*"] - [filename]

        if sibling_files.length > 1
          raise StandardError.new("More than one template found for #{self}. There can only be one sidecar template file per component.")
        end

        if sibling_files.length == 0
          raise NotImplementedError.new(
            "Could not find a template for #{self}. Either define a .template method or add a sidecar template file."
          )
        end

        sibling_files[0]
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

    attr_reader :content
  end
end
