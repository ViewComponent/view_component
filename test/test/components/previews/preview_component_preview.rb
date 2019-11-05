# frozen_string_literal: true

class PreviewComponentPreview < ActionView::Component::Preview
  def default
    { cta: "Click me!", title: "Lorem Ipsum" }
  end

  def without_cta
    { title: "More lorem..." }
  end
end
