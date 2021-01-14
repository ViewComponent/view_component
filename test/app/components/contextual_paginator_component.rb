# frozen_string_literal: true

class ContextualPaginatorComponent < ViewComponent::Base
  include ViewComponent::SlotableV2

  renders_one :page, "PageComponent"
  renders_one :current_page, "PageComponent"

  def initialize(max:, current:)
    @max = max
    @current = current
  end

  class PageComponent < ViewComponent::Base
    attr_reader :number

    def initialize(number: nil)
      @number = number
    end

    def call
      content
    end
  end
end
