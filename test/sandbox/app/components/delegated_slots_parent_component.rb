# frozen_string_literal: true

class DelegatedSlotsParentComponent < ViewComponent::Base
  renders_one :header, ->(text:, color: "black") do
    content_tag(:p, class: "header color-#{color}") { text }
  end

  renders_many :items, ->(text:, color: "black") do
    content_tag(:li, class: "item color-#{color}") { text }
  end
end
