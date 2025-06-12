# frozen_string_literal: true

module ViewComponent
  module WithContentHelper
    def with_content(value)
      raise NilWithContentError if value.nil?

      @__vc_content_set_to_with_content_value = false
      @__vc_content_set_by_with_content = value

      self
    end
  end
end
