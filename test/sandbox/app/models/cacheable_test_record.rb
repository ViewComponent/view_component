# frozen_string_literal: true

# Minimal stand-in for an ActiveRecord model with cache versioning enabled:
# a stable cache_key plus a cache_version that changes when the record is updated.
class CacheableTestRecord
  attr_reader :id, :version

  def initialize(id:, version:)
    @id = id
    @version = version
  end

  def cache_key
    "cacheable_test_record/#{id}"
  end

  def cache_version
    version.to_s
  end

  def cache_key_with_version
    "#{cache_key}-#{cache_version}"
  end
end
