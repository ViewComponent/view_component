# frozen_string_literal: true

class TestSlimComponent < ActionView::Component
  validates :content, presence: true

  def initialize(message:)
    @message = message
  end
end
