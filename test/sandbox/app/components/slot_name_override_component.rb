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

class SlotNameOverrideComponent::OtherComponent < ViewComponent::Base
  renders_one :title
end

class SlotNameOverrideComponent::SubComponent < SlotNameOverrideComponent
  def title
    super.upcase
  end
end
