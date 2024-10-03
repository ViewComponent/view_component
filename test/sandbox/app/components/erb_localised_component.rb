# frozen_string_literal: true

class ErbLocalisedComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
