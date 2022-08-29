# frozen_string_literal: true

class MyComponentPreview < ViewComponent::Preview
  layout "admin"

  def default
    render(MyComponent.new)
  end

  def with_content(content:)
    render(MyComponent.new.with_content(content))
  end

  def inside_banner
    render_with_template
  end
end
