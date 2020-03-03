# frozen_string_literal: true

module ViewComponent
  class TemplateError < StandardError
    def initialize(errors)
      super(errors.join(", "))
    end
  end
end
