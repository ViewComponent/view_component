# frozen_string_literal: true

class RequestUrlComponentPreview < ViewComponent::Preview
  def default
    render(RequestUrlComponent.new)
  end
end
