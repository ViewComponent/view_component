class TurboContentTypeComponent < ViewComponent::Base
  def initialize(message: "Enter a message:", show_form: true)
    @message = message
    @show_form = show_form
  end

  def call
    content_tag('turbo-frame', id: "test-frame") do
      if show_form
        form_content
      else
        content_tag(:div, @message, id: "result")
      end
    end
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