# frozen_string_literal: true

module CacheDigestFixtures
  autoload :RaisingRubyDependency, Rails.root.join("test/fixtures/cache_digest/raising_ruby_dependency.rb")
end

class CacheableRaisingRubyDependencyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  def call
    render CacheDigestFixtures::RaisingRubyDependency.new
  end
end
