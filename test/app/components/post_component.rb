# frozen_string_literal: true

class PostComponent < ActionView::Component::Base
  def initialize(title:)
    @title = title
  end
end
