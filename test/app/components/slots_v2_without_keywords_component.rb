# frozen_string_literal: true

class SlotsV2WithoutKeywordsComponent < ViewComponent::Base
  renders_one :title, "MyTitleComponent"
  renders_many :items, "MyItemComponent"

  class MyTitleComponent < ViewComponent::Base
    def initialize(text)
      @text = text
    end

    def call
      tag.h1(@text)
    end
  end

  class MyItemComponent < ViewComponent::Base
    def initialize(text)
      @text = text
    end

    def call
      tag.li(@text)
    end
  end
end
