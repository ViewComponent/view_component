# frozen_string_literal: true

class MyComponentPreview < ActionView::Component::Preview
  layout "admin"

  def default
    render(MyComponent)
  end
end
