# frozen_string_literal: true

class Performance::NameComponent < ViewComponent::Base
  def initialize(name:, nested: true)
    @name = name
    @nested = nested
  end
end
