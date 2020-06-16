# frozen_string_literal: true

class HelpersContainerComponent < ViewComponent::Base

  def call
    render HelpersProxyComponent.new
  end
end
