# frozen_string_literal: true

class ConditionalRenderComponent < ActionView::Component::Base
  validates :should_render, inclusion: { in: [true, false] }

  before_render do
    unless [true, false].include?(should_render)
      raise RuntimeError.new("should_render wasn't validated!")
    end

    self.rendered_output = "" unless should_render
  end

  attr_reader :should_render
  private :should_render

  def initialize(should_render:)
    @should_render = should_render
  end
end
