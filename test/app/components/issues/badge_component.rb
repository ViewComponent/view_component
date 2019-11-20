# frozen_string_literal: true

module Issues
  class BadgeComponent < ActionView::Component::Base
    STATES = {
      open: {
        color: :green,
        label: "Open",
      },
      closed: {
        color: :red,
        label: "Closed",
      },
    }.freeze

    validates :state, inclusion: {in: STATES.keys}

    def initialize(state:)
      @state = state
    end

    private

    attr_reader :state
  end
end
