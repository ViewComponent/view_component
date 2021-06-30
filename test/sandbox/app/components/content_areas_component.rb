# frozen_string_literal: true

class ContentAreasComponent < ViewComponent::Base
  with_content_areas :title, :body, :footer

  def initialize(title: nil, footer: nil)
    @title = title
    @footer = footer
  end
end
