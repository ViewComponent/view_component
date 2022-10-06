# frozen_string_literal: true

class SuperBaseComponent < ViewComponent::Base
  renders_one :parent_slot
end
