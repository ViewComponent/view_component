# frozen_string_literal: true

class ErbComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
