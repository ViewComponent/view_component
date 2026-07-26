# frozen_string_literal: true

class CacheRecordComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [record] }
  attr_reader :record

  def initialize(record:)
    @record = record
  end
end
