# frozen_string_literal: true

class AfterRenderComponent < ViewComponent::Base
  def call
    "Hello, "
  end

  def _output_postamble
    "World!"
  end
end
