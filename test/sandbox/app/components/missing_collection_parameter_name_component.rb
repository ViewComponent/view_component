# frozen_string_literal: true

class MissingCollectionParameterNameComponent < ViewComponent::Base
  with_collection_parameter :foo

  # rubocop:disable Style/RedundantInitialize
  def initialize(bar:)
  end
  # rubocop:enable Style/RedundantInitialize
end
