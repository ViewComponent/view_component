# frozen_string_literal: true

class ButtonToComponent < ActionView::Component::Base
  validates :content, presence: true

  def initialize(*); end
end
