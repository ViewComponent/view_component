# frozen_string_literal: true

class CacheableRaisingExplicitDependencyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  # Template Dependency: CacheDigestFixtures::RaisingRubyDependency

  def call
    "unreachable"
  end
end
