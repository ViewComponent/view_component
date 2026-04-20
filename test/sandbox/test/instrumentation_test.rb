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
    assert_match("app/components/instrumentation_component.html.erb", events[0].payload[:view_identifier])
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

  def test_compile_instrumentation
    events = []
    subscriber = ActiveSupport::Notifications.subscribe("compile.view_component") do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end

    old_eager_load = Rails.application.config.eager_load
    Rails.application.config.eager_load = true

    ViewComponent::CompileCache.invalidate!

    # Execute the same block that the view_component.eager_load_actions initializer registers
    initializer = ViewComponent::Engine.initializers.find { |i| i.name == "view_component.eager_load_actions" }
    initializer.run(Rails.application)

    assert_equal(1, events.size)
    assert_equal("compile.view_component", events[0].name)
  ensure
    Rails.application.config.eager_load = old_eager_load
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
