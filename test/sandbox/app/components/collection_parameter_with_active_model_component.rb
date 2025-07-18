# frozen_string_literal: true

class CollectionParameterWithActiveModelComponent < ViewComponent::Base
  include ActiveModel::Attributes

  attribute :name, :string

  with_collection_parameter :name

  def initialize(name:)
  end

  def call
  end
end
