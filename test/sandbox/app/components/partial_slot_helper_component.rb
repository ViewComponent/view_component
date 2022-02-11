# frozen_string_literal: true

class PartialSlotHelperComponent < ViewComponent::Base
  renders_one :header, PartialHelperComponent
end
