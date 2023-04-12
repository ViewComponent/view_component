# frozen_string_literal: true

class SlotsDelegateComponent < ViewComponent::Base
  renders_many :items, SlotsComponent::MyHighlightComponent
end
