# frozen_string_literal: true

class UnsafePreambleComponent < ViewComponent::Base
  def call
    "<div>some content</div>".html_safe
  end

  def output_preamble
    "<script>alert('hello!')</script>"
  end
end
