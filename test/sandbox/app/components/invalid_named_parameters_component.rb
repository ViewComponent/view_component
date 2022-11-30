# frozen_string_literal: true

class InvalidNamedParametersComponent < ViewComponent::Base
  def initialize(content:)
    @content = content
  end
end
