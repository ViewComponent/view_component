# frozen_string_literal: true

class InitializerTranslationsComponent < ViewComponent::Base
  def initialize
    @title = t(".title")
  end
end
