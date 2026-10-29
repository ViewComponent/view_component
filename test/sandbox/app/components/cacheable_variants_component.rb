# frozen_string_literal: true

class CacheableVariantsComponent < VariantsComponent
  cache_on :identity

  private

  def identity
    "same"
  end
end
