# frozen_string_literal: true

class HelperWithKeywordsComponent < ViewComponent::Base
  def initialize(kwd1:, kwd2:)
    @kwd1 = kwd1
    @kwd2 = kwd2
  end
end
