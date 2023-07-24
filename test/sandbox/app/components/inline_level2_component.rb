# frozen_string_literal: true

class InlineLevel2Component < Level2Component
  def call
    "<div level2-component base>#{render_parent_to_string}</div>"
  end

  def call_variant
    "<div level2-component variant>#{render_parent_to_string}</div>"
  end
end
