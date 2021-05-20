# frozen_string_literal: true

class HelperWithArgumentsKeywordsAndBlockComponent < ViewComponent::Base
  def initialize(arg1, arg2, kwd1:, kwd2:)
    @arg1 = arg1
    @arg2 = arg2
    @kwd1 = kwd1
    @kwd2 = kwd2
  end
end
