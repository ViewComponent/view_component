# frozen_string_literal: true

require "active_support/concern"

module ActionView
  module Component # :nodoc:
    module Previewable
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
  end
end
