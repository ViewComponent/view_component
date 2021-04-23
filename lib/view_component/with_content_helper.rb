# frozen_string_literal: true

module ViewComponent
  module WithContentHelper
    def with_content(value)
      if value.nil?
        raise ArgumentError.new("No content provided.")
      else
        @_content_set_by_with_content = value
      end

      self
    end
  end
end
