# frozen_string_literal: true

require "test_helper"

class InstrumentationTest < ViewComponent::TestCase
  def test_instrumentation
    events = []
    ActiveSupport::Notifications.subscribe("!render.view_component") do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end
    render_inline(InstrumentationComponent.new)

    assert_selector("div", text: "hello,world!")
    assert_equal(events.size, 1)
    assert_equal(events[0].name, "!render.view_component")
    assert_equal(events[0].payload[:name], "InstrumentationComponent")
    assert_match("app/components/instrumentation_component.rb", events[0].payload[:identifier])
  end
end
