# frozen_string_literal: true

class CacheDependencyTypesComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :record, :tags, :label, :private_token

  attr_reader :record, :tags, :label

  def initialize(record:, tags:, label:)
    @record = record
    @tags = tags
    @label = label
  end

  private

  def private_token
    "private-token"
  end
end
