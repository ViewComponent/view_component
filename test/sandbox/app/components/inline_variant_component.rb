# frozen_string_literal: true

class InlineVariantComponent < ViewComponent::Base
  def call
  end

  def call_inline_variant
    text_field_tag :inline_variant
  end
end
