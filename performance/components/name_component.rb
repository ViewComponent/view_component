# frozen_string_literal: true

class Performance::NameComponent < ViewComponent::Base
  def initialize(name:)
    @name = name
  end
end
