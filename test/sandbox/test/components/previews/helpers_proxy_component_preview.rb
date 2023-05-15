# frozen_string_literal: true

class HelpersProxyComponentPreview < ViewComponent::Preview
  def default
    render(HelpersProxyComponent.new)
  end
end
