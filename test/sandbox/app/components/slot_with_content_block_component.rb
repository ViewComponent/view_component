# frozen_string_literal: true

class SlotWithContentBlockComponent < ViewComponent::Base
  renders_one :header

  def call
    out = +""
    out << content_tag(:div, header, class: "header") if header?
    out << content_tag(:div, content, class: "body") if content?
    out.html_safe
  end
end
