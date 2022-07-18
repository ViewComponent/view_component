# frozen_string_literal: true

class ComposableSlotsComponent < ViewComponent::Base
  delegate :title, to: :@parent

  def initialize
    @parent = SlotsV2WithoutContentBlockComponent.new
  end

  def call
    content_tag :div, class: "composable-slot-component" do
      capture do
        render @parent
      end
    end
  end
end
