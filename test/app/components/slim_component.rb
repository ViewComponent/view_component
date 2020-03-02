# frozen_string_literal: true

class SlimComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
