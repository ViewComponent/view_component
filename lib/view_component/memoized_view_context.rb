# frozen_string_literal: true

module ViewComponent
  module MemoizedViewContext
    def view_context
      @_view_context ||= super
    end
  end
end
