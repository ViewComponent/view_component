# frozen_string_literal: true

class CallbacksComponent < ActionView::Component::Base
  before_render :before
  around_render :around
  after_render  :after

  attr_reader :events

  def initialize(*)
    @events = []
  end

  def before
    events << :before
  end

  def around
    events << :before_around
    yield
    events << :after_around
  end

  def after
    events << :after
  end
end
