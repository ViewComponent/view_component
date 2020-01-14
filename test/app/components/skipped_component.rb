# frozen_string_literal: true

class SkippedComponent < ActionView::Component::Base
  render_if { false }

  def initialize(*); end
end
