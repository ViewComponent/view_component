# frozen_string_literal: true

class BeforeAndAfterRenderComponent < ViewComponent::Base
  def call
    "Hello, ".html_safe
  end

  def output_preamble
    "Well, ".html_safe
  end

  def output_postamble
    "World!".html_safe
  end
end
