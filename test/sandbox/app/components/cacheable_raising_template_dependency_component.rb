# frozen_string_literal: true

class CacheableRaisingTemplateDependencyComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable
end
