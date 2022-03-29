# frozen_string_literal: true

require "active_support/concern"

module ViewComponent
  module Previewable
    extend ActiveSupport::Concern

    class_methods do
      def _application_config
        Rails.application.config.view_component
      end

      %i[show_previews_source show_previews preview_paths preview_path preview_route
         default_preview_layout preview_controller].each do |method_name|
        delegate method_name, "#{method_name}=".to_sym, to: :_application_config
      end
    end
  end
end
