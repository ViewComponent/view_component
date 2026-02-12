# frozen_string_literal: true

class CacheDependencyTypesRecord
  include ActiveModel::Model
  include GlobalID::Identification

  attr_accessor :id

  def self.find(id)
    new(id: id)
  end
end

class CacheDependencyTypesComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :record_gid, :tags, :label, :private_token

  attr_reader :record, :tags, :label

  def initialize(record:, tags:, label:)
    @record = record
    @tags = tags
    @label = label
  end

  def record_gid
    record.to_global_id
  end

  private

  def private_token
    "private-token"
  end
end
