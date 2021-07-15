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

  def with_tag_helper_in_content
    render(PreviewComponent.new(title: "title")) { content_tag(:span, "some content") }
  end

  def with_params(cta: "Default CTA", title: "Default title")
    render(PreviewComponent.new(cta: cta, title: title))
  end
end
