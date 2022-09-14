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
        raise ArgumentError.new(
          "Unknown content_area '#{area}' for #{self} - expected one of '#{content_areas}'.\n\n" \
          "To fix this issue, add `with_content_area :#{area}` to #{self} or reference " \
          "a valid content area."
        )
      end

      if block
        content = view_context.capture(&block)
      end

      instance_variable_set("@#{area}".to_sym, content)
      nil
    end

    class_methods do
      def with_content_areas(*areas)
        ViewComponent::Deprecation.warn(
          "`with_content_areas` is deprecated and will be removed in ViewComponent v3.0.0.\n\n" \
          "Use slots (https://viewcomponent.org/guide/slots.html) instead."
        )

        if areas.include?(:content)
          raise ArgumentError.new(
            "#{self} defines a content area called :content, which is a reserved name. \n\n" \
            "To fix this issue, use another name, such as `:body`."
          )
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
