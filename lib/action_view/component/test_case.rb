# frozen_string_literal: true

require "active_support/test_case"

module ActionView
  module Component
    class TestCase < ActiveSupport::TestCase
      include ActionView::Component::TestHelpers
    end
  end
end
