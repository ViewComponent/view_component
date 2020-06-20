# frozen_string_literal: true

require "active_support/concern"

module ViewComponent # :nodoc:
  module Previewable
    extend ActiveSupport::Concern

    included do
      # Set the location of component previews through app configuration:
      #
      #     config.view_component.preview_paths << "#{Rails.root}/lib/component_previews"
      #
      mattr_accessor :preview_paths, instance_writer: false

      # Enable or disable component previews through app configuration:
      #
      #     config.view_component.show_previews = true
      #
      # Defaults to +true+ for development environment
      #
      mattr_accessor :show_previews, instance_writer: false

      # Set the entry route for component previews through app configuration:
      #
      #     config.view_component.preview_route = "/previews"
      #
      # Defaults to +/rails/view_components+ when `show_previews' is enabled
      #
      mattr_accessor :preview_route, instance_writer: false do
        "/rails/view_components"
      end
    end
  end
end
