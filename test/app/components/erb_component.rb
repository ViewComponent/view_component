# frozen_string_literal: true

class ErbComponent < ActionView::Component
  validates :content, presence: true

  def initialize(message:)
    @message = message
  end
end
