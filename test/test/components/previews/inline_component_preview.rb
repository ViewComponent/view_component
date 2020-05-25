# frozen_string_literal: true

class InlineComponentPreview < ViewComponent::Preview
  def default
    render(InlineComponent.new)
  end

  def inside_form
  end

  def outside_form
  end
end
