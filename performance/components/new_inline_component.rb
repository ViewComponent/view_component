# frozen_string_literal: true

class Performance::NewInlineComponent < ViewComponent::Base
  class NestedComponent < ViewComponent::Base
    def initialize(name:)
      @name = name
    end

    erb_template <<~ERB
      <p>nested hello #{@name}</p>
    ERB
  end

  def initialize(name:)
    @name = name
  end

  erb_template <<~ERB
    <h1>hello #{@name}</h1>
    <%=
      safe_join(
        [
          content,
          50.times.map { render NestedComponent.new(name: @name) }
        ],
        "\n\n"
      )
    %>
  ERB
end
