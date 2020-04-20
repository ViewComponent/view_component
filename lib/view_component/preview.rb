# frozen_string_literal: true

require "active_support/descendants_tracker"

module ViewComponent # :nodoc:
  class Preview
    include ActionView::Helpers::TagHelper
    extend ActiveSupport::DescendantsTracker

    def render(component, **args, &block)
      { component: component, args: args, block: block }
    end

    class << self
      # Returns all component preview classes.
      def all
        load_previews if descendants.empty?
        descendants
      end

      # Returns the arguments for rendering of the component in its layout
      def render_args(example, params: {})
        example_params_names = instance_method(example).parameters.map(&:last)
        provided_params = params.slice(*example_params_names).to_h.symbolize_keys
        result = provided_params.empty? ? new.public_send(example) : new.public_send(example, **provided_params)
        result.merge(layout: @layout)
      end

      # Returns the component object class associated to the preview.
      def component
        name.chomp("Preview").constantize
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

      # Returns the underscored name of the component preview without the suffix.
      def preview_name
        name.chomp("Preview").underscore
      end

      # Setter for layout name.
      def layout(layout_name)
        @layout = layout_name
      end

      private

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
