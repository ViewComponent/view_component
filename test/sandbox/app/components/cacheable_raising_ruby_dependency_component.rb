# frozen_string_literal: true

class CacheableRaisingRubyDependencyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  def call
    render CacheDigestFixtures::RaisingRubyDependency.new
  end
end
