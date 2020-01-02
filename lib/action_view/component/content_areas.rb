# frozen_string_literal: true

module ActionView
  module Component # :nodoc:
    module ContentAreas
      extend ActiveSupport::Concern

      included do
        class_attribute :content_areas, default: []
        self.content_areas = [] # default doesn't work until Rails 5.2
      end

      class_methods do
        def set_content_areas(*areas)
          if areas.include?(:content)
            raise StandardError.new ":content is a reserved content_area internal to ActionView:Component. Please use another area name, perhaps ':body'"
          end
          attr_reader *areas
          self.content_areas = areas
        end
      end

      def with(area, content = nil, &block)
        unless content_areas.include?(area)
          raise StandardError.new "Unknown content_area '#{area}' - expected one of '#{content_areas}'"
        end

        if block_given?
          content = view_context.capture(&block)
        end

        set_area(area, content)
        nil
      end

      private

      def set_area(area, value)
        instance_variable_name = "@#{area}".to_sym
        instance_variable_set(instance_variable_name, value)
      end
    end
  end
end
