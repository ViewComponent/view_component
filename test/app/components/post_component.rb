# frozen_string_literal: true

class PostComponent < ActionView::Component::Base
  def initialize(post)
    @post = post
  end
end
