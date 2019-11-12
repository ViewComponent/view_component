# frozen_string_literal: true

module Issues
  class BadgePreview < ActionView::Component::Preview
    def open
      render(Issues::Badge, state: :open)
    end

    def closed
      render(Issues::Badge, state: :closed)
    end
  end
end
