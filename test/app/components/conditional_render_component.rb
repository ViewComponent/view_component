# frozen_string_literal: true

class ConditionalRenderComponent < ViewComponent::Base
  def initialize(should_render:)
    @should_render = should_render
  end

  attr_reader :should_render

  def render?
    unless [true, false].include?(should_render)
      raise RuntimeError.new("should_render wasn't validated!")
    end

    should_render
  end
end
