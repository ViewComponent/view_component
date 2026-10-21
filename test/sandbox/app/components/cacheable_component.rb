# frozen_string_literal: true

class CacheableComponent < ViewComponent::Base
  cache_on :title

  def initialize(title:)
    @title = title
  end

  private

  attr_reader :title
end
