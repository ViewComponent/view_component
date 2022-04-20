# frozen_string_literal: true

class LambdaSlotComponent < ViewComponent::Base
  renders_one :header, ->(classes:, &block) do
    content_tag :h1, class: classes, &block
  end
end
