# frozen_string_literal: true

class CurrentPageComponent < ViewComponent::Base
  def text
    "#{current_page?("/slots") ? "Inside" : "Outside"} /slots (#{request.method} #{request.path})"
  end
end
