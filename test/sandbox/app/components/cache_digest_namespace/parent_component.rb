# frozen_string_literal: true

module CacheDigestNamespace
  class ParentComponent < ViewComponent::Base
    def call
      render ChildComponent.new
    end
  end
end
