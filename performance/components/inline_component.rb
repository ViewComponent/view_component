# frozen_string_literal: true

class Performance::InlineComponent < ViewComponent::Base
  class NestedComponent < ViewComponent::Base
    def initialize(name:)
      @name = name
    end

    def call
      "<p>nested hello #{@name}</p>".html_safe
    end
  end

  def initialize(name:)
    @name = name
  end

  def call
    content = "<h1>hello #{@name}</h1>".html_safe

    safe_join(
      [
        content,
        50.times.map { render NestedComponent.new(name: @name) }
      ],
      "\n\n"
    )
  end
end
