# frozen_string_literal: true

class CacheIndirectParentComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [:indirect] }

  def indirect_child
    render(CacheDigestorChildComponent.new)
  end
end
