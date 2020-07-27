# frozen_string_literal: true

class MyHighlightComponent < ViewComponent::Base
  def initialize(highlighted: false)
    @highlighted = highlighted
  end

  def call
    content
  end

  def classes
    @highlighted ? "highlighted" : "normal"
  end
end
