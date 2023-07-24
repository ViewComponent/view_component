# frozen_string_literal: true

class InlineLevel3Component < Level2Component
  def call
    content_tag(:div, class: "level3-component base") do
      render_parent
    end
  end

  def call_variant
    content_tag(:div, class: "level3-component variant") do
      render_parent
    end
  end
end
