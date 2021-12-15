# frozen_string_literal: true

class LambdaSlotPassthroughComponent < ViewComponent::Base
  renders_one :lambda_slot, ->(&block) { self.class.new(&block) }
end
