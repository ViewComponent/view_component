# frozen_string_literal: true

class ActionViewComponentPreview < ActionView::Component::Preview
  layout "admin"

  def default
    render(ActionViewComponent)
  end
end
