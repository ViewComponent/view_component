# frozen_string_literal: true

class MessageComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end

  def call
    html_escape(@message)
  end
end
