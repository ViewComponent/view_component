# frozen_string_literal: true

module NestedSharedState
  class TableComponent < ViewComponent::Base
    include ViewComponent::SlotableV2

    renders_one :header, -> (**system_arguments, &block) do
      header_system_arguments = system_arguments
      header_system_arguments[:selectable] = @selectable

      header_component = NestedSharedState::HeaderComponent.new(**header_system_arguments)
      render(header_component) do
        block.call(header_component)
      end
    end

    # @param selectable [Boolean] When enabled it allows the user to select rows using checkboxes
    def initialize(selectable: false)
      @selectable = selectable
    end
  end
end
