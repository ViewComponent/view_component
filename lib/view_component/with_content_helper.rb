# frozen_string_literal: true

module ViewComponent
  module WithContentHelper # Provides the `with_content` helper for setting string content values
    def with_content(value)
      raise NilWithContentError if value.nil?

      @__vc_content_set_by_with_content = value

      self
    end
  end
end
