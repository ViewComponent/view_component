# frozen_string_literal: true

class ConditionalRenderComponent < ActionView::Component::Base
<<<<<<< HEAD
  validates :should_render, inclusion: { in: [true, false] }

  def initialize(should_render:)
    @should_render = should_render
  end

  attr_reader :should_render

  def render?
    unless [true, false].include?(should_render)
      raise RuntimeError.new("should_render wasn't validated!")
    end

    should_render
=======
  before_render do
    self.rendered_output = "" unless should_render
  end

  attr_reader :should_render
  private :should_render

  def initialize(should_render:)
    @should_render = should_render
>>>>>>> add (before|around|after)_render hooks
  end
end
