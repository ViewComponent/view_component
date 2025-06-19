# frozen_string_literal: true

require "active_support/test_case"

module ViewComponent
  # Base test case for unit tests of ViewComponents. Includes `ViewComponent::TestHelpers`.
  class TestCase < ActiveSupport::TestCase
    include ViewComponent::TestHelpers
  end
end
