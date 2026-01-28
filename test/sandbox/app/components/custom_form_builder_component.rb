# frozen_string_literal: true

class CustomFormBuilderComponent < ViewComponent::Base
  def initialize(builder:)
    @builder = builder
  end
end
