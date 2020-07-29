# frozen_string_literal: true

class HamlComponent < ViewComponent::Base
  def initialize(message:, url: nil)
    @message = message
    @url = url
  end
end
