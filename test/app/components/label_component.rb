# frozen_string_literal: true
#
class LabelComponent < ActionView::Component::Base
  def initialize(form:)
    @form = form
  end

  private

  attr_reader :form
end
