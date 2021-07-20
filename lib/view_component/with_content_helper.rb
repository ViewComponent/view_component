# frozen_string_literal: true

module ViewComponent
  module WithContentHelper
    def with_content(value)
      if value.nil?
        raise ArgumentError.new(
          "No content provided to `#with_content` for #{self}.\n\n" \
          "To fix this issue, pass a value."
        )
      else
        @__vc_content_set_by_with_content = value
      end

      self
    end
  end
end
