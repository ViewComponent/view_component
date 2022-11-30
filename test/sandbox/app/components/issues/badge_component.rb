# frozen_string_literal: true

module Issues
  class BadgeComponent < ViewComponent::Base
    STATES = {
      open: {
        color: :green,
        label: "Open"
      },
      closed: {
        color: :red,
        label: "Closed"
      }
    }.freeze

    def initialize(state:)
      @state = state
    end

    private

    attr_reader :state
  end
end
