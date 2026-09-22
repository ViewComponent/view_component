# frozen_string_literal: true

class RaisingCacheDigestComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :identity

  class_attribute :raise_on_digest, default: false

  def self.sidecar_files(*)
    raise "boom" if raise_on_digest

    super
  end

  def call
    "raising cache digest"
  end

  private

  def identity
    "raising-cache-digest"
  end
end
