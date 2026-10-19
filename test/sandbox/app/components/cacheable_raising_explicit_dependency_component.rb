# frozen_string_literal: true

class CacheableRaisingExplicitDependencyComponent < ViewComponent::Base
  # Template Dependency: CacheDigestFixtures::RaisingRubyDependency

  def call
    "unreachable"
  end
end
