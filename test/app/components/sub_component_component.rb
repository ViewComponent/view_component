# frozen_string_literal: true

class SubComponentComponent < ViewComponent::Base
  include ViewComponent::SubComponents

  renders_one :title
  renders_one :subtitle
  renders_one :footer, -> (classes: "", &block) do
    content_tag :footer, class: "footer #{classes}" do
      block.call if block
    end
  end

  renders_many :tabs

  renders_many :items, -> (highlighted: false) do
    MyHighlightComponent.new(highlighted: highlighted)
  end

  def initialize(classes: "")
    @classes = classes
  end
end
