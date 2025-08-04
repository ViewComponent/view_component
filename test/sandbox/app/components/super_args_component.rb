# frozen_string_literal: true

class SuperArgsComponent < ViewComponent::Base
  erb_template <<-ERB
    <h1><%= @message %></h1>
  ERB

  def initialize(message)
    @message = message
    super
  end
end