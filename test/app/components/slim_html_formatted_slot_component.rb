# frozen_string_literal: true

class SlimHTMLFormattedSlotComponent < ViewComponent::Base
  def unsafe_html
    "<script>alert('xss')</script"
  end
end
