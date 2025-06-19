# frozen_string_literal: true

class MissingCollectionParameterNameComponent < ViewComponent::Base
  with_collection_parameter :foo

  def initialize(bar:)
  end
end
