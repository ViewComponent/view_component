# frozen_string_literal: true

class NoLayoutPreview < ActionView::Component::Preview
  layout false

  def default
    render(MyComponent)
  end
end
