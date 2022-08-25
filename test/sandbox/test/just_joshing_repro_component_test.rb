# frozen_string_literal: true

require "test_helper"

class JustJoshingReproComponentTest < ViewComponent::TestCase
  def test_repro
    render_inline JustJoshingReproComponent.new do |c|
      c.with_slot1 do
        render JustJoshingReproComponent.new do
          "Content"
        end
      end
    end
  end
end
