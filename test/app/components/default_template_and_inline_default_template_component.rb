# frozen_string_literal: true

class DefaultTemplateAndInlineDefaultTemplateComponent < ViewComponent::Base
  def call
    content_tag :div do
      "Inline Template"
    end
  end
end
