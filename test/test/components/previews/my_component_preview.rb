# frozen_string_literal: true

class MyComponentPreview < ViewComponent::Preview
  layout "admin"

  def default
    render(MyComponent.new)
  end

  def inside_banner
    render_with_template
  end
end
