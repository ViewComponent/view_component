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
        def with_content_areas(*areas)
          if areas.include?(:content)
            raise ArgumentError.new ":content is a reserved content area name. Please use another name, such as ':body'"
          end
          attr_reader *areas
          self.content_areas = areas
        end
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
    end
  end
end
