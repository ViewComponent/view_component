# frozen_string_literal: true

class SlotsV2WithoutContentBlockComponent < ViewComponent::Base
  include ViewComponent::SlotableV2

  renders_one :title, "MyTitleComponent"

  class MyTitleComponent < ViewComponent::Base
    def initialize(title:)
      @title = title
    end

    def call
      content_tag :h1, @title
    end
  end
end
