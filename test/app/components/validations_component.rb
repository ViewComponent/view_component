# frozen_string_literal: true

class ValidationsComponent < ActionView::Component::Base
  validates :content, presence: true
end
