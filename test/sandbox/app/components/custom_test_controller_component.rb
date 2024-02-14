# frozen_string_literal: true

class CustomTestControllerComponent < ViewComponent::Base
  def call
    html_escape(helpers.foo)
  end
end
