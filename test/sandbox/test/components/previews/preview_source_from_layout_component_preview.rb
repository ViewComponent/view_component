# frozen_string_literal: true

class PreviewSourceFromLayoutComponentPreview < ViewComponent::Preview
  layout "component_preview"

  def default_with_template
    render_with_template
  end
end
