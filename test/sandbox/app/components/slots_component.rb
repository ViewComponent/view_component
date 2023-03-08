# frozen_string_literal: true

class SlotsComponent < ViewComponent::Base
  renders_one :title
  renders_one :subtitle
  renders_one :footer, ->(classes: "", &block) do
    content_tag :footer, class: "footer #{classes}" do
      block.call if block
    end
  end

  renders_many :tabs

  renders_many :items, ->(highlighted: false) do
    MyHighlightComponent.new(highlighted: highlighted)
  end
  renders_one :extra, "ExtraComponent"

  def initialize(classes: "")
    @classes = classes
  end

  class MyHighlightComponent < ViewComponent::Base
    def initialize(highlighted: false)
      @highlighted = highlighted
    end

    def classes
      @highlighted ? "highlighted" : "normal"
    end

    def method_with_kwargs(*args, **kwargs)
      kwargs
    end
  end

  class ExtraComponent < ViewComponent::Base
    def initialize(message:)
      @message = message
    end

    def call
      render(ErbComponent.new(message: @message)) { content }
    end
  end
end
