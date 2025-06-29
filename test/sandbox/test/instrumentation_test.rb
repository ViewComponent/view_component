# frozen_string_literal: true

require "test_helper"

class InstrumentationTest < ViewComponent::TestCase
  def test_instrumentation_for_include
    events = []
    ActiveSupport::Notifications.subscribe("render.view_component") do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end

    render_inline(InstrumentationComponent.new)

    assert_selector("div", text: "hello,world!")
    assert_equal(events.size, 1)
    assert_equal("render.view_component", events[0].name)
    assert_equal(events[0].payload[:name], "InstrumentationComponent")
    assert_match("app/components/instrumentation_component.rb", events[0].payload[:identifier])
  end

  def test_instrumentation_disabled
    with_instrumentation_enabled_option(false) do
      events = []
      ActiveSupport::Notifications.subscribe("render.view_component") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      render_inline(InstrumentationComponent.new)

      assert_selector("div", text: "hello,world!")
      assert_equal(events.size, 0)
    end
  end
end
