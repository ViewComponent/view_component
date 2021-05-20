# frozen_string_literal: true

class HelperWithArgumentsComponent < ViewComponent::Base
  def initialize(arg1, arg2)
    @arg1 = arg1
    @arg2 = arg2
  end
end
