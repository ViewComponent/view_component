# frozen_string_literal: true

class SlottedContentChildComponent < ViewComponent::Base
  def has_content?
    !content.nil?
  end
end
