class TagComponent < ViewComponent::Base

  def initialize(text)
    @text = text
  end

  def call
    content_tag :span, text, class: "tag"
  end
end