# frozen_string_literal: true

class InlineLevel2Component < InlineLevel1Component
  def call
    "<div class='level2-component base'>#{render_parent_to_string}</div>".html_safe
  end

  def call_variant
    "<div class='level2-component variant'>#{render_parent_to_string}</div>".html_safe
  end
end
