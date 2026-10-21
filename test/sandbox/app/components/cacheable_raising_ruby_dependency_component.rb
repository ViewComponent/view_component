# frozen_string_literal: true

class CacheableRaisingRubyDependencyComponent < ViewComponent::Base
  def call
    render CacheDigestFixtures::RaisingRubyDependency.new
  end
end
