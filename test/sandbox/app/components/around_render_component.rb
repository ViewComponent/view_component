# frozen_string_literal: true

class AroundRenderComponent < ViewComponent::Base
  def call
    "Hello, "
  end

  def output_preamble
    "Why "
  end

  def output_postamble
    "World!"
  end
end
