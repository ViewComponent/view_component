# frozen_string_literal: true

class NestedComponent < ViewComponent::Base
  strip_trailing_whitespace

  erb_template <<~ERB
    <%= render ChildComponent.new %>
  ERB

  class ChildComponent < ViewComponent::Base
    strip_trailing_whitespace

    erb_template <<~ERB
      <h1>Leaf</h1>
    ERB
  end
end
