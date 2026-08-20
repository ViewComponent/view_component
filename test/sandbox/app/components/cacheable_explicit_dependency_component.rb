# frozen_string_literal: true

# Renders a partial that static analysis can't see, declared with the
# `# Template Dependency:` escape hatch.
class CacheableExplicitDependencyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: integration_examples/erb_partial

  def initialize(partial: "integration_examples/erb_partial")
    @partial = partial
  end

  private

  attr_reader :partial
end
