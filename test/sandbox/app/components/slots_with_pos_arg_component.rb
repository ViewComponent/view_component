# frozen_string_literal: true

class SlotsWithPosArgComponent < ViewComponent::Base
  renders_many :items, "Item"

  class Item < ViewComponent::Base
    attr_reader :title, :classes

    def initialize(title, classes:)
      @title = title
      @classes = classes
    end

    def call
      content
    end
  end
end
