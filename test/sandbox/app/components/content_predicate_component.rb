# frozen_string_literal: true

class ContentPredicateComponent < ViewComponent::Base
  def call
    if content?
      content
    else
      "Default".html_safe
    end
  end
end
