# frozen_string_literal: true

class RequestUrlComponentPreview < ViewComponent::Preview
  def default
    render(RequestUrlComponent.new)
  end

  def with_id(id:)
    render(RequestUrlComponent.new) { id }
  end
end
