# frozen_string_literal: true

require "test_helper"

class InstrumentationTest < ViewComponent::TestCase
  def test_instrumentation
    with_config_option(:use_deprecated_instrumentation_name, false) do
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
  end

  def test_instrumentation_with_deprecated_name
    events = []
    ActiveSupport::Notifications.subscribe("!render.view_component") do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end
    render_inline(InstrumentationComponent.new)

    assert_equal(events.size, 1)
    assert_equal("!render.view_component", events[0].name)
  end
end
