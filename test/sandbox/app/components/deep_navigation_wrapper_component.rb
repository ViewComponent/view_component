# frozen_string_literal: true

class DeepNavigationWrapperComponent < ViewComponent::Base
  def call
    render "shared/deep_navigation"
  end
end
