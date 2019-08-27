# frozen_string_literal: true

class WrapperComponent < ActionView::Component::Base
  validates :content, presence: true

  def initialize(*); end
end
