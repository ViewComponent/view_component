# frozen_string_literal: true

class CacheableCallPartialComponent < ViewComponent::Base
  def call
    render "integration_examples/erb_partial"
  end
end
