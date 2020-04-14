# frozen_string_literal: true

class VariantTemplateAndInlineVariantTemplateComponent < ViewComponent::Base
  def call_phone
    content_tag :div do
      "Inline Variant Template"
    end
  end
end
