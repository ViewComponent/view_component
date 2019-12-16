# frozen_string_literal: true

require "active_support/configurable"

module ActionView
  module Component
    class Base < ActionView::Base
      include ActiveModel::Validations
      include ActiveSupport::Configurable
      include ActionView::Component::Previewable

      delegate :form_authenticity_token, :protect_against_forgery?, to: :helpers

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
        @virtual_path ||= virtual_path
        @variant = @lookup_context.variants.first
        old_current_template = @current_template
        @current_template = self

        @content = view_context.capture(&block) if block_given?
        validate!

        send(self.class.call_method_name(@variant))
      ensure
        @current_template = old_current_template
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

      private

      def request
        @request ||= controller.request
      end

      attr_reader :content, :view_context

      class << self
        def inherited(child)
          child.include Rails.application.routes.url_helpers unless child < Rails.application.routes.url_helpers

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
          # Require #initialize to be defined so that we can use
          # method#source_location to look up the file name
          # of the component.
          #
          # If we were able to only support Ruby 2.7+,
          # We could just use Module#const_source_location,
          # rendering this unnecessary.
          raise NotImplementedError.new("#{self} must implement #initialize.") unless self.instance_method(:initialize).owner == self

          instance_method(:initialize).source_location[0]
        end

        # Compile templates to instance methods, assuming they haven't been compiled already.
        # We could in theory do this on app boot, at least in production environments.
        # Right now this just compiles the first time the component is rendered.
        def compile
          return if @compiled && ActionView::Base.cache_template_loading

          validate_templates

          templates.each do |template|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
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

        private

        def matching_views_in_source_location
          (Dir["#{source_location.sub(/#{File.extname(source_location)}$/, '')}.*{#{ActionView::Template.template_handler_extensions.join(',')}}"] - [source_location])
        end

        def templates
          @templates ||=
            matching_views_in_source_location.each_with_object([]) do |path, memo|
              pieces = File.basename(path).split(".")

              memo << {
                path: path,
                variant: pieces.second.split("+")[1]&.to_sym,
                handler: pieces.last
              }
            end
        end

        def validate_templates
          if templates.empty?
            raise NotImplementedError.new("Could not find a template file for #{self}.")
          end

          if templates.select { |template| template[:variant].nil? }.length > 1
            raise StandardError.new("More than one template found for #{self}. There can only be one default template file per component.")
          end

          variants.each_with_object(Hash.new(0)) { |variant, counts| counts[variant] += 1 }.each do |variant, count|
            next unless count > 1

            raise StandardError.new("More than one template found for variant '#{variant}' in #{self}. There can only be one template file per variant.")
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
end
