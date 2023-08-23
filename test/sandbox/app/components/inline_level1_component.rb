# frozen_string_literal: true

class InlineLevel1Component < ViewComponent::Base
  def call
    content_tag(:div, class: "level1-component") do
      "Level 1 component"
    end
  end
end
