# frozen_string_literal: true

class CacheableComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :title

  def initialize(title:)
    @title = title
  end

  private

  attr_reader :title
end
