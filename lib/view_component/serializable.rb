# frozen_string_literal: true

require "active_support/concern"
require "view_component/serializable/proxy"

module ViewComponent
  module Serializable
    extend ActiveSupport::Concern

    class UnserializableError < ArgumentError; end

    class_methods do
      # Returns a Proxy that captures this class and its initialization arguments,
      # deferring instantiation until render time. The proxy is renderable and
      # serializable for ActiveJob (e.g. Turbo Streams). Slot calls made on the
      # proxy are captured and replayed at render time. Blocks are not supported.
      #
      #   MyComponent.render_later("title", size: :large).with_item(label: "One")
      def render_later(*args)
        ViewComponent::Serializable::Proxy.new(self, *args)
      end
      ruby2_keywords :render_later
    end
  end
end
