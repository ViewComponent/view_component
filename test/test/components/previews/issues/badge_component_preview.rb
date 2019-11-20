# frozen_string_literal: true

module Issues
  class BadgeComponentPreview < ActionView::Component::Preview
    def open
      render(Issues::BadgeComponent, state: :open)
    end

    def closed
      render(Issues::BadgeComponent, state: :closed)
    end
  end
end
