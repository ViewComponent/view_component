# frozen_string_literal: true

class InlineLevel3Component < InlineLevel2Component
  def call
    content_tag(:div, class: "level3-component base") do
      render_parent_to_string
    end
  end

  def call_variant
    content_tag(:div, class: "level3-component variant") do
      render_parent_to_string
    end
  end
end
