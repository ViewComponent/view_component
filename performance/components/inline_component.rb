# frozen_string_literal: true

class Performance::InlineComponent < ViewComponent::Base
  def initialize(name:, nested: true)
    @name = name
    @nested = nested
  end

  def call
    # rubocop:disable Rails/OutputSafety
    content = "<h1>hello #{@name}</h1>".html_safe

    if @nested
      safe_join([
        content,
        50.times.map { InlineComponent.new(name: @name, nested: false) }
      ])
    else
      content
    end
  end
end
