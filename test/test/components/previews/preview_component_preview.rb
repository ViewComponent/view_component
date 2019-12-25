# frozen_string_literal: true

class PreviewComponentPreview < ActionView::Component::Preview
  def default
    render(PreviewComponent, cta: "Click me!", title: "Lorem Ipsum")
  end

  def without_cta
    render(PreviewComponent, title: "More lorem...")
  end

  def with_content
    render(PreviewComponent, title: "title") { "some content" }
  end
end
