# frozen_string_literal: true

class SubComponentDelegateComponent < ViewComponent::Base
  include ViewComponent::SubComponents

  renders_many :items, SubComponentComponent::MyHighlightComponent

  def initialize
  end
end
