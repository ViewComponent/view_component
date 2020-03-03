# frozen_string_literal: true

class PreviewComponentPreview < ViewComponent::Preview
  def default
    render(PreviewComponent.new(cta: "Click me!", title: "Lorem Ipsum"))
  end

  def without_cta
    render(PreviewComponent.new(title: "More lorem..."))
  end

  def with_content
    render(PreviewComponent.new(title: "title")) { "some content" }
  end
end
