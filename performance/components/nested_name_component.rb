# frozen_string_literal: true

class Performance::NestedNameComponent < ViewComponent::Base
  def initialize(name:)
    @name = name
  end
end
