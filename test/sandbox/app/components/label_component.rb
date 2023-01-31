# frozen_string_literal: true

class LabelComponent < ViewComponent::Base
  include ViewComponent::CaptureCompatibility

  def initialize(form:)
    @form = form
  end

  private

  attr_reader :form
end
