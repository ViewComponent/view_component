# frozen_string_literal: true

class SlotsWithEmptyLambdaComponent < ViewComponent::Base
  renders_many :items, -> do
    @item_count += 1
    Item.new("Title #{@item_count}")
  end

  def initialize
    @item_count = 0
  end

  class Item < ViewComponent::Base
    attr_reader :title

    def initialize(title)
      @title = title
    end

    def call
      content
    end
  end
end
