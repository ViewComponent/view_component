# frozen_string_literal: true

require "view_component"

module ViewComponent
  module FragmentCaching
    def self.enable!
      ViewComponent::Base.include(ViewComponent::Cacheable) unless ViewComponent::Base < ViewComponent::Cacheable
    end
  end
end

ViewComponent::FragmentCaching.enable!
