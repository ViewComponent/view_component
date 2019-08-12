# frozen_string_literal: true

class TestWrapperComponent < ActionView::Component
  validates :content, presence: true

  def initialize(*); end
end
