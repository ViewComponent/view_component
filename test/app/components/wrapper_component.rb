# frozen_string_literal: true

class WrapperComponent < ActionView::Component
  validates :content, presence: true

  def initialize(*); end
end
