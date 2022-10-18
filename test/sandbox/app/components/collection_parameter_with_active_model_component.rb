# frozen_string_literal: true

class CollectionParameterWithActiveModelComponent < ViewComponent::Base
  # This file gets eager loaded, so we have to check the Rails version to avoid
  # including a module that doesn't exist in older Rails versions. The tests that
  # render this component are skipped under older versions as well.
  if Rails::VERSION::STRING >= "5.2"
    include ActiveModel::Attributes

    attribute :name, :string
  end

  with_collection_parameter :name

  def call
  end
end
