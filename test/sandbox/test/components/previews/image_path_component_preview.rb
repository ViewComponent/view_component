# frozen_string_literal: true

class ImagePathComponentPreview < ViewComponent::Preview
  def default
    render(MessageComponent.new(message: image_path("foo.png")))
  end
end
