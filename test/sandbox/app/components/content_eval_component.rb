# frozen_string_literal: true

class ContentEvalComponent < ViewComponent::Base
  def call
    content # evaluate content
    content_tag :h1, "content!"
  end
end
