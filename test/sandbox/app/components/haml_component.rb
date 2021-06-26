# frozen_string_literal: true

class HamlComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
