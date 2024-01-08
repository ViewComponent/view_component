# frozen_string_literal: true

class UnsafePostambleComponent < ViewComponent::Base
  def call
    "<div>some content</div>".html_safe
  end

  def output_postamble
    "<script>alert('hello!')</script>"
  end
end
