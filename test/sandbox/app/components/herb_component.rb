# frozen_string_literal: true

class HerbComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
