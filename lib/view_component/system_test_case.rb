# frozen_string_literal: true

require "active_support/test_case"

module ViewComponent
  class SystemTestCase < ActionDispatch::SystemTestCase
    include ViewComponent::SystemTestHelpers

    def page
      Capybara.current_session
    end
  end
end
