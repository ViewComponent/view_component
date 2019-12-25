# frozen_string_literal: true

require "active_support/descendants_tracker"

module ActionView
  module Component # :nodoc:
    class Preview
      extend ActiveSupport::DescendantsTracker
      include ActionView::Component::TestHelpers

      def render(component, *locals, &block)
        render_inline(component, *locals, &block)
      end

      class << self
        # Returns all component preview classes.
        def all
          load_previews if descendants.empty?
          descendants
        end

        # Returns the html of the component in its layout
        def call(example, layout: nil, example_args: {})

          example_html = example_html(example, example_args)
          if layout.nil?
            layout = @layout.nil? ? "layouts/application" : @layout
          end

          Rails::ComponentExamplesController.render(template: "examples/show",
                                                    layout: layout,
                                                    assigns: { example: example_html })
        end

        # Returns the component object class associated to the preview.
        def component
          self.name.sub(%r{Preview$}, "").constantize
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
          name.sub(/Preview$/, "").underscore
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

        def example_html(example, params)
          example_method = new.public_method(example)

          if example_method.arity == 0
            example_method.call
          else
            method_args = example_method.parameters.map(&:last)
            example_method.call(**params.slice(*method_args))
          end
        end
      end
    end
  end
end
