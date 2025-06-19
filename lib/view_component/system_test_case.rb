# frozen_string_literal: true

require "active_support/test_case"

module ViewComponent
  # Base test case for system tests of ViewComponents. Includes `ViewComponent::SystemTestHelpers`.
  class SystemTestCase < ActionDispatch::SystemTestCase
    include ViewComponent::SystemTestHelpers

    # Set `page` for Capybara to visit
    def page
      Capybara.current_session
    end
  end
end
