# frozen_string_literal: true

class UrlHelperComponentPreview < ViewComponent::Preview
  def default
    render(UrlHelperComponent.new(url: root_path))
  end
end
