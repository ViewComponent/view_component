# frozen_string_literal: true

class Unsuffixed::OtherPreview < ViewComponent::Preview
  def other
    render(Unsuffixed::Other.new)
  end
end
