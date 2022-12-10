# frozen_string_literal: true

require "active_support/deprecation"

module ViewComponent
  DEPRECATION_HORIZON = "3.0.0"
  Deprecation = ActiveSupport::Deprecation.new(DEPRECATION_HORIZON, "ViewComponent")
end
