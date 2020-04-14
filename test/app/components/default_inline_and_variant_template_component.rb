# frozen_string_literal: true

class DefaultInlineAndVariantTemplateComponent < ViewComponent::Base
  def call
    content_tag :div do
      "Inline Template"
    end
  end

  def call_phone
    content_tag :div do
      "Inline Phone Template"
    end
  end
end
