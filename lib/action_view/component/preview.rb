# frozen_string_literal: true

require "active_support/descendants_tracker"
require_relative "test_helpers"

module ActionView
  module Component #:nodoc:
    module Previews
      extend ActiveSupport::Concern

      included do
        # Set the location of component previews through app configuration:
        #
        #     config.action_view_component.preview_path = "#{Rails.root}/lib/component_previews"
        #
        mattr_accessor :preview_path, instance_writer: false

        # Enable or disable component previews through app configuration:
        #
        #     config.action_view_component.show_previews = true
        #
        # Defaults to +true+ for development environment
        #
        mattr_accessor :show_previews, instance_writer: false
      end
    end

    class Preview
      extend ActiveSupport::DescendantsTracker

      attr_reader :params

      def initialize(params = {})
        @params = params
      end

      class << self
        include ActionView::Component::TestHelpers

        # Returns all component preview classes.
        def all
          load_previews if descendants.empty?
          descendants
        end

        # Returns the rendered component.
        def call(example, params = {})
          preview = new(params)
          locals = preview.public_send(example)
          render_inline(component, locals)
        end

        # Returns the component object class associated to the preview.
        def component
          self.name.sub(%r{Preview$}, '').constantize
        end

        # Returns all of the available examples for the component preview.
        def examples
          public_instance_methods(false).map(&:to_s).sort
        end

        # Returns +true+ if the example of the component preview exists.
        def example_exists?(example)
          examples.include?(example)
        end

        # Returns +true+ if the preview exists.
        def exists?(preview)
          all.any? { |p| p.preview_name == preview }
        end

        # Find a component preview by its underscored class name.
        def find(preview)
          all.find { |p| p.preview_name == preview }
        end

        # Setter for layout name
        def set_layout(layout_name)
          @layout_name ||= layout_name
        end

        # Returns the path of the layout to be used when rendering the component
        def layout
          ensure_layout_exists

          @layout_path
        end

        # Returns the underscored name of the component preview without the suffix.
        def preview_name
          name.sub(/Preview$/, "").underscore
        end

        private

        def ensure_layout_exists
          @layout_name ||= 'application'

          unless @layout_path = Dir["#{preview_path}/layouts/#{@layout_name}.*"].first
            raise StandardError.new("Layout #{@layout_name} does not exist. It must be present in '#{preview_path}/layouts/#{@layout_name}.*'")
          end
        end

        def load_previews
          if preview_path
            Dir["#{preview_path}/**/*_preview.rb"].sort.each { |file| require_dependency file }
          end
        end

        def preview_path
          Base.preview_path
        end

        def show_previews
          Base.show_previews
        end
      end
    end
  end
end
