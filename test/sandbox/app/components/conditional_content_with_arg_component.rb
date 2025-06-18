# frozen_string_literal: true

class ConditionalContentWithArgComponent < ViewComponent::Base
  def initialize(description: nil)
    @description = description
  end

  def call
    description&.html_safe
  end

  private

  def description
    @description || content
  end
end
