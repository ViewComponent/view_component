# frozen_string_literal: true

# A helper that renders a component, for components to include.
module CacheableChildHelper
  def cacheable_child
    render CacheableChildComponent.new
  end
end
