# frozen_string_literal: true

module NestedSharedState
  class RowComponent < ViewComponent::Base
    include ViewComponent::SlotableV2

    renders_many :cells, ->(*args, **kwargs, &block) do
      render(NestedSharedState::CellComponent.new(*args, **kwargs)) do
        block.call
      end
    end

    def initialize(id: nil, selectable: false, checked: false, **system_arguments)
      @id = id
      @checked = checked
      @selectable = selectable
      @system_arguments = system_arguments
    end
  end
end