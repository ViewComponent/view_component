# frozen_string_literal: true

class UnsuffixedPreview < ViewComponent::Preview
  def default
    render(Unsuffixed.new)
  end
end
