# frozen_string_literal: true

class ActionViewComponent < ActionView::Component::Base
  validates :content, presence: true

  def initialize(*); end
end
