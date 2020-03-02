# frozen_string_literal: true

require "active_support/test_case"

module ViewComponent
  class TestCase < ActiveSupport::TestCase
    include ViewComponent::TestHelpers
  end
end
