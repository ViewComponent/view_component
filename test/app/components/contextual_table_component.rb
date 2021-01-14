# frozen_string_literal: true

class ContextualTableComponent < ViewComponent::Base
  include ViewComponent::SlotableV2

  renders_many :columns, ->(*path, **kwargs) { ColumnComponent.new(path: path, **kwargs) }

  attr_reader :data

  def initialize(data:)
    @data = data
  end

  class ColumnComponent < ViewComponent::Base
    attr_reader :label, :path, :item

    def initialize(label: nil, path: nil, item: nil)
      @label = label
      @path = [*path]
      @item = item
    end

    def value
      item.dig(*path) if item && !path.empty?
    end

    def call
      content || value
    end
  end
end
