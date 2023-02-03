# frozen_string_literal: true

class PolymorphicContentSlotComponent < ViewComponent::Base
  renders_one :leading_visual, prefix: true, types: {
    icon: lambda { |title|
      content_tag("h1") do
        title
      end
    }
  }

  def before_render
    content
  end
end
