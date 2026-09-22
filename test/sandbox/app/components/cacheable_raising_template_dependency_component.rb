# frozen_string_literal: true

module CacheDigestFixtures
  autoload :RaisingTemplateDependency, Rails.root.join("test/fixtures/cache_digest/raising_template_dependency.rb")
end

class CacheableRaisingTemplateDependencyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable
end
