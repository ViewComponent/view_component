# frozen_string_literal: true

module ViewComponent
  module ActionTextable
    if require("action_text")
      require "action_text/engine"
      include ActionText::Engine.helpers

      def main_app
        Rails.application.class.routes.url_helpers
      end
    end
  end
end
