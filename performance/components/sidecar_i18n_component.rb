# frozen_string_literal: true

class SidecarI18nComponent < ViewComponent::Base
  include ViewComponent::SidecarI18n

  def initialize(key)
    @key = key
  end

  def self.virtual_path
    "/sidecar_i18n_component"
  end
end
