# frozen_string_literal: true

class ContentPredicateComponent < ViewComponent::Base
  def call
    if content?
      content
    else
      "Default"
    end
  end
end
