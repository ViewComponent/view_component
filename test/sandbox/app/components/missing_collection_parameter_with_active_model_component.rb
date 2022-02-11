# frozen_string_literal: true

class MissingCollectionParameterWithActiveModelComponent < ViewComponent::Base
  include ActiveModel::Model
  if Rails.version.to_f >= 5.2
    include ActiveModel::Attributes
  end

  with_collection_parameter :name

  def call; end
end
