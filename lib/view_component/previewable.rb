# frozen_string_literal: true

require "active_support/concern"

module ViewComponent
  module Previewable
    extend ActiveSupport::Concern

    included do
      # Enable or disable component previews:
      #
      #     config.view_component.show_previews = true
      #
      # Defaults to `true` in development.
      #
      mattr_accessor :show_previews, instance_writer: false

      # Enable or disable source code previews in component previews:
      #
      #     config.view_component.show_previews_source = true
      #
      # Defaults to `false`.
      #
      mattr_accessor :show_previews_source, instance_writer: false, default: false

      # Set a custom default layout used for preview index and individual previews:
      #
      #     config.view_component.default_preview_layout = "component_preview"
      #
      # Defaults to nil.
      #
      mattr_accessor :default_preview_layout, instance_writer: false

      # Set the location of component previews:
      #
      #     config.view_component.preview_paths << "#{Rails.root}/lib/component_previews"
      #
      # Defaults to `[]`.
      #
      mattr_accessor :preview_paths, instance_writer: false

      # @deprecated Use `preview_paths` instead. Will be removed in v3.0.0.
      mattr_accessor :preview_path, instance_writer: false

      # Set the entry route for component previews:
      #
      #     config.view_component.preview_route = "/previews"
      #
      # Defaults to `/rails/view_components` when `show_previews` is enabled.
      #
      mattr_accessor :preview_route, instance_writer: false do
        "/rails/view_components"
      end

      # Set the controller used for previewing components:
      #
      #     config.view_component.preview_controller = "MyPreviewController"
      #
      # Defaults to `ViewComponentsController`.
      #
      mattr_accessor :preview_controller, instance_writer: false do
        "ViewComponentsController"
      end
    end
  end
end
