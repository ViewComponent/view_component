# frozen_string_literal: true

# Declares both a slot and `cache_on`, so callers setting the slot must be
# rejected while a default-filled slot must not be.
class CacheableSlotComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  renders_one :header

  cache_on :title

  def initialize(title:)
    @title = title
  end

  def default_header
    "default header"
  end

  private

  attr_reader :title
end
