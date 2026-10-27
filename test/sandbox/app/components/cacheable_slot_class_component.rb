# frozen_string_literal: true

# Renders a child only through a slot declared with the child's class.
class CacheableSlotClassComponent < ViewComponent::Base
  renders_one :header, CacheableChildComponent
end
