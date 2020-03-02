# frozen_string_literal: true

module Issues
  class BadgeComponentPreview < ViewComponent::Preview
    def open
      render(Issues::BadgeComponent.new(state: :open))
    end

    def closed
      render(Issues::BadgeComponent.new(state: :closed))
    end
  end
end
