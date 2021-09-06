# frozen_string_literal: true

require "active_support/test_case"

module ViewComponent
  class SystemTestCase < ActionDispatch::SystemTestCase
    include ViewComponent::SystemTestHelpers
  end
end
