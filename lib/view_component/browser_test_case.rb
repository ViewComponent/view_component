# frozen_string_literal: true

require "active_support/test_case"

module ViewComponent
  class BrowserTestCase < ActiveSupport::TestCase
    include ViewComponent::BrowserTestHelpers
  end
end
