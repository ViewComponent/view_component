# frozen_string_literal: true

class MissingCollectionParameterWithActiveModelComponent < ViewComponent::Base
  include ActiveModel::Model
  include ActiveModel::Attributes

  with_collection_parameter :name

  def call
  end
end
