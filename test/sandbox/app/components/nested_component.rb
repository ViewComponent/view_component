# frozen_string_literal: true

class NestedComponent < ViewComponent::Base
  module Builder
    CONTENT = [{
      type: "root",
      children: [
        { type: "leaf" },
        { type: "leaf" },
        { type: "leaf" },
      ]
    }]

    def build(obj)
      klass =
        case obj
        when { type: "root" } then RootComponent
        when { type: "leaf" } then LeafComponent
        end

      klass.new(obj)
    end

    def initialize(obj = CONTENT)
      @obj = obj
    end
  end

  include Builder

  strip_trailing_whitespace

  erb_template <<~ERB
    <div data-wrapper>
      <% @obj.each do |obj| %>
        <%= render build(obj) %>
      <% end %>
    </div>
  ERB

  class RootComponent < ViewComponent::Base
    include Builder

    strip_trailing_whitespace

    erb_template <<~ERB
      <div data-root>
        <% @obj[:children].each do |obj| %>
          <%= render build(obj) %>
        <% end %>
      </div>
    ERB
  end

  class LeafComponent < ViewComponent::Base
    include Builder

    strip_trailing_whitespace

    erb_template <<~ERB
      <span data-leaf>
        Leaf
      </span>
    ERB
  end
end
