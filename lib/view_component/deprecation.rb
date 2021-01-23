# frozen_string_literal: true

require "active_support/deprecation"

module ViewComponent
  Deprecation = ActiveSupport::Deprecation.new("3.0", "ViewComponent")
end
