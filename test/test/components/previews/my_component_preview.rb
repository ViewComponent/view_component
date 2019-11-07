# frozen_string_literal: true

class MyComponentPreview < ActionView::Component::Preview
  set_layout :admin

  def default
    render(MyComponent)
  end
end
