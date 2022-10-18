# frozen_string_literal: true

class DefaultFormBuilderComponent < ViewComponent::Base
  def default_form_builder
    controller.default_form_builder
  end
end
