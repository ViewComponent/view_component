# frozen_string_literal: true

# Renders a child built by a method, so the child's class appears in no
# `render` call.
class CacheableMethodBuiltComponent < ViewComponent::Base
  private

  def child
    CacheableChildComponent.new
  end
end
