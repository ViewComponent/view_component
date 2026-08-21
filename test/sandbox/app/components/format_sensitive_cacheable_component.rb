# frozen_string_literal: true

# Renders the requested format, so a cache entry shared across formats is
# visible in the output.
class FormatSensitiveCacheableComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :identity

  def call
    view_context.lookup_context.formats.first.to_s.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def identity
    "same-component"
  end
end
