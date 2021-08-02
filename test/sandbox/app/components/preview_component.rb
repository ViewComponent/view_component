# frozen_string_literal: true

class PreviewComponent < ViewComponent::Base
  def initialize(cta: nil, title:)
    @cta = cta
    @title = title
  end

  private

  attr_reader :cta, :title
end
