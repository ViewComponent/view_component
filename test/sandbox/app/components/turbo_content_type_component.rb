class TurboContentTypeComponent < ViewComponent::Base
  def initialize(message: "Enter a message:", show_form: true)
    @message = message
    @show_form = show_form
  end

  private

  attr_reader :message, :show_form
end
