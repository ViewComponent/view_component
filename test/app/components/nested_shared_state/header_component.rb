# frozen_string_literal: true

module NestedSharedState
  class HeaderComponent < ViewComponent::Base
    include ViewComponent::SlotableV2

    renders_many :cells, ->(*args, **kwargs, &block) do
      render(NestedSharedState::CellComponent.new(*args, **kwargs)) do
        block.call
      end
    end

    def initialize(selectable: false, class_names: 'table__header', **kwargs)
      @selectable = selectable
      @class_names = class_names
    end
  end
end
