# frozen_string_literal: true

# Counts renders so cache hits are observable.
class ConditionalCacheProbeComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :identity, if: :cacheable?

  class_attribute :render_count, default: 0

  def initialize(cacheable:)
    @cacheable = cacheable
  end

  def call
    self.class.render_count += 1
    "render-#{self.class.render_count}".html_safe
  end

  private

  def cacheable?
    @cacheable
  end

  def identity
    "constant"
  end
end
