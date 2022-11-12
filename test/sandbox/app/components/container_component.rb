# frozen_string_literal: true

class ContainerComponent < ViewComponent::Base
  def call
    if Rails.application.config.view_component.render_monkey_patch_enabled || Rails.version.to_f >= 6.1
      render HelpersProxyComponent.new
    else
      render_component HelpersProxyComponent.new
    end
  end
end
