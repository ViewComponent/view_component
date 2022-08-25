# frozen_string_literal: true

class JustJoshingReproComponent < ViewComponent::Base
  renders_one :slot1, -> (&block) do
    # Won't render slot2 content unless I call 'render' here.
    render JustJoshingReproComponent.new do |c|
      c.with_slot2(&block)
    end
  end

  renders_one :slot2
end
