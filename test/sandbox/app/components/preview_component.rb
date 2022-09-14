# frozen_string_literal: true

class PreviewComponent < ViewComponent::Base
  def initialize(title:, cta: nil)
    @cta = cta
    @title = title
  end

  private

  attr_reader :cta, :title
end
