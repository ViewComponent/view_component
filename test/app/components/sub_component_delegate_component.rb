# frozen_string_literal: true

class SubComponentDelegateComponent < ViewComponent::Base
  include ViewComponent::SubComponents

  renders_many :items, MyHighlightComponent

  def initialize
  end
end
