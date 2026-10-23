# frozen_string_literal: true

class Performance::NestedNameComponent < ViewComponent::Base
  with_collection_parameter :name

  def initialize(name:)
    @name = name
  end
end
