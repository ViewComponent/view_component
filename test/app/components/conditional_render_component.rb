# frozen_string_literal: true

class ConditionalRenderComponent < ViewComponent::Base
  def initialize(should_render:)
    @should_render = should_render
  end

  def render?
    @should_render
  end
end
