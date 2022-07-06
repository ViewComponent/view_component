# frozen_string_literal: true

class InvalidParametersComponent < ViewComponent::Base
  def initialize(content)
    @content = content
  end
end
