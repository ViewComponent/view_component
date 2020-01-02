# frozen_string_literal: true

class ContentAreasComponent < ActionView::Component::Base
  validates :body, :title, :footer, presence: true

  set_content_areas :title, :body, :footer

  def initialize(title: nil, footer: nil)
    @title = title
    @footer = footer
  end
end
