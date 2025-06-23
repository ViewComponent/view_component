# frozen_string_literal: true

module ViewComponent
  module Configurable
    extend ActiveSupport::Concern

    included do
      next if respond_to?(:config) && config.respond_to?(:view_component) && config.respond_to_missing?(:instrumentation_enabled)

      include ActiveSupport::Configurable

      configure do |config|
        config.view_component ||= ActiveSupport::InheritableOptions.new
      end
    end
  end
end
