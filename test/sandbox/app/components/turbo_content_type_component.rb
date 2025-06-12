class TurboContentTypeComponent < ViewComponent::Base
  def initialize(message: "Enter a message:", show_form: true)
    @message = message
    @show_form = show_form
  end

  private

  attr_reader :message, :show_form

  def form_content
    form_tag("/submit", method: :post, data: { turbo_frame: "test-frame" }) do
      content_tag(:div) do
        content_tag(:h2, @message) +
        text_field_tag("user_message", "", value: "Test message") +
        content_tag(:br) +
        submit_tag("Submit", id: "submit")
      end
    end
  end
end
