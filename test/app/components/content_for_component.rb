# frozen_string_literal: true

class ContentForComponent < ActionView::Component::Base
  validates :content, :title, :footer, presence: true

  attr_reader :content, :title, :footer

  def initialize(title: nil, footer: nil)
    @title = title
    @footer = footer
  end
end
