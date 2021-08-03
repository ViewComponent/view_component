# frozen_string_literal: true

class InlineComponent < ViewComponent::Base
  def initialize(name:)
    @name = name
  end

  def call
    # rubocop:disable Rails/OutputSafety
    "<h1>hello #{@name}</h1>".html_safe
  end
end
