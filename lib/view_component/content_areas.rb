# frozen_string_literal: true

require "active_support/concern"

require "view_component/slot"

# DEPRECATED - ContentAreas is deprecated and will be removed in v3.0.0
module ViewComponent
  module ContentAreas
    extend ActiveSupport::Concern

    # Assign the provided content to the content area accessor
    #
    # @private
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

    class_methods do
      def with_content_areas(*areas)
        ActiveSupport::Deprecation.warn(
          "`with_content_areas` is deprecated and will be removed in ViewComponent v3.0.0.\n" \
          "Use slots (https://viewcomponent.org/guide/slots.html) instead."
        )

        if areas.include?(:content)
          raise ArgumentError.new ":content is a reserved content area name. Please use another name, such as ':body'"
        end

        areas.each do |area|
          define_method area.to_sym do
            content unless content_evaluated? # ensure content is loaded so content_areas will be defined
            instance_variable_get(:"@#{area}") if instance_variable_defined?(:"@#{area}")
          end
        end

        self.content_areas = areas
      end
    end
  end
end
