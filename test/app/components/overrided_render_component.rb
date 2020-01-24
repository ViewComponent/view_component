# frozen_string_literal: true

class OverridedRenderComponent < ActionView::Component::Base
  around_render :render_cached

  attr_reader :version
  private :version

  def initialize(version:)
    @version = version
  end

  def render_cached
    self.rendered_output = Rails.cache.fetch("cached-component") do
      yield
    end
  end
end
