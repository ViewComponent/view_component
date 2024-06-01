# frozen_string_literal: true

class SlotNameOverrideComponent < ViewComponent::Base
  renders_one :title

  def initialize(title: nil)
    @title = title
  end

  def title
    @title || super
  end

  def title?
    @title.present? || super
  end
end
