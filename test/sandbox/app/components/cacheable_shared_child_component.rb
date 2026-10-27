# frozen_string_literal: true

# Renders two components that both render CacheableChildComponent, so its
# digest tree reaches the child twice.
class CacheableSharedChildComponent < ViewComponent::Base
  def call
    safe_join([render(CacheableParentComponent.new), render(CacheableCallComponent.new)])
  end
end
