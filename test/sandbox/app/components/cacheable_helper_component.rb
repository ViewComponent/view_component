# frozen_string_literal: true

# Renders a child through a helper from an included module.
class CacheableHelperComponent < ViewComponent::Base
  include CacheableChildHelper

  def call
    cacheable_child
  end
end
