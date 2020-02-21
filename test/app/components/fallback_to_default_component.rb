# frozen_string_literal: true

class FallbackToDefaultComponent < ActionView::Component::Base
  DEFAULT_COLOR = :blue
  COLOR_OPTIONS = [DEFAULT_COLOR, :red, :green]

  def initialize(color:)
    @color = from_options_with_default(color, DEFAULT_COLOR, COLOR_OPTIONS)
  end
end
