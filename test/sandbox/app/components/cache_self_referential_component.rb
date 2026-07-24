# frozen_string_literal: true

class CacheSelfReferentialComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [:self] }

  private

  def render_self?
    false
  end
end
