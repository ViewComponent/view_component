# frozen_string_literal: true

class InlineRenderComponent < ViewComponent::Base
  def initialize(items:)
    @items = items
  end

  def call
    @items.map { |c| render(c) }.join
  end
end
