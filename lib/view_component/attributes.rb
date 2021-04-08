# frozen_string_literal: true

require "active_support/concern"

# An attributes API for declaratively defining properties a component accepts.
# @example
#   class PostComponent
#     include ViewComponent::Attributes
#
#     accepts :title, required: true
#     accepts :posted_at, required: true
#
#     accepts :author, default: NullUser.new
#   end
#
#   <%= render PostComponent.new(title: "foo", posted_at: Date.yesterday %>
module ViewComponent
  module Attributes
    extend ActiveSupport::Concern

    included do
      cattr_accessor :_optional_attributes, default: {}
      cattr_accessor :_required_attributes, default: {}
    end

    class_methods do
      def accepts(parameter, required: false, default: nil)
        if required
          _required_attributes[parameter] = default
        else
          _optional_attributes[parameter] = default
        end

        attr_accessor parameter
      end
    end

    def initialize(**args)
      _construct_attributes(args)
    end

    private

    def _construct_attributes(args)
      _required_attributes.each do |attr, _default|
        if !args.has_key?(attr)
          raise ArgumentError.new("Missing keyword: #{attr}") # Simulate required kwargs
        end

        instance_variable_set("@#{attr}", args[attr])
      end

      _optional_attributes.each do |attr, default|
        if args.has_key?(attr)
          value = args[attr]
          instance_variable_set("@#{attr}", value)
        else
          value = args[attr]
          instance_variable_set("@#{attr}", default)
        end
      end
    end
  end
end
