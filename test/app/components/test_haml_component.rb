# frozen_string_literal: true

class TestHamlComponent < ActionView::Component
  validates :content, presence: true

  def initialize(message:)
    @message = message
  end
end
