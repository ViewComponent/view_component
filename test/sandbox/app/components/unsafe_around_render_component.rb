# frozen_string_literal: true

class UnsafeAroundRenderComponent < ViewComponent::Base
  def initialize(unsafe_around_render: nil)
    @unsafe_around_render = unsafe_around_render
  end

  def call
    "safe".html_safe
  end

  def around_render
    yield
    "<script>alert(1)</script>"
  end
end
