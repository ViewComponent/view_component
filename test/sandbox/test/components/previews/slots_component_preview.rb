# frozen_string_literal: true

class SlotsComponentPreview < ViewComponent::Preview
  def default
    render(SlotsComponent.new) do |component|
      component.with_title do
        "Hello, world!"
      end
    end
  end

  def with_concat
    render(SlotsComponent.new) do |component|
      component.with_title do
        concat "Hello, world!"
      end
    end
  end
end
