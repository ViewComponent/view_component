# frozen_string_literal: true

module ViewComponent
  class Slot
    attr_accessor :content

    def with_content(this_content)
      self.content = this_content

      self
    end
  end
end
