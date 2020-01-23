# frozen_string_literal: true

class OverridedRenderComponent < ActionView::Component::Base
  attr_reader :version
  private :version

  def initialize(version:)
    @version = version
  end

  def render_template
    Rails.cache.fetch("cached-component") do
      super
    end
  end
end
