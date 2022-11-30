# frozen_string_literal: true

require "active_support/deprecation"

module ViewComponent
  DEPRECATION_HORIZON = 3
  Deprecation = ActiveSupport::Deprecation.new(DEPRECATION_HORIZON.to_s, "ViewComponent")
end
