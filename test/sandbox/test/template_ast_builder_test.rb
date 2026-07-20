# frozen_string_literal: true

require "test_helper"

# Canary tests for the ActionView coupling in TemplateAstBuilder.
#
# `build` constructs an ActionView::Template and invokes the handler to compile a
# template string down to Ruby (which cache digesting then scans for render
# dependencies). Both the Template constructor and the handler-call convention are
# Rails internals that have changed across versions. If a future Rails upgrade
# breaks either one, `build` returns nil and these assertions fail loudly here,
# instead of silently degrading to empty dependencies and producing stale caches.
class TemplateAstBuilderTest < ViewComponent::TestCase
  def test_build_compiles_erb_to_ruby_containing_render
    ruby = ViewComponent::TemplateAstBuilder.build("<%= render CacheComponent.new %>", :erb)

    refute_nil(ruby, "ERB handler coupling broke: build returned nil")
    assert_includes(ruby, "render")
  end

  def test_build_compiles_slim_to_ruby_containing_render
    ruby = ViewComponent::TemplateAstBuilder.build("= render CacheComponent.new", :slim)

    refute_nil(ruby, "Slim handler coupling broke: build returned nil")
    assert_includes(ruby, "render")
  end

  def test_build_compiles_haml_to_ruby_containing_render
    ruby = ViewComponent::TemplateAstBuilder.build("= render CacheComponent.new", :haml)

    refute_nil(ruby, "Haml handler coupling broke: build returned nil")
    assert_includes(ruby, "render")
  end

  def test_build_emits_instrumentation_when_compilation_fails
    events = []
    subscriber = ActiveSupport::Notifications.subscribe("template_ast_build_failed.view_component") do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end

    # Force handler.call to raise so we exercise the rescue path.
    handler = ActionView::Template.handler_for_extension(:erb)
    handler.stub(:call, ->(*) { raise "boom" }) do
      assert_nil(ViewComponent::TemplateAstBuilder.build("<%= 1 %>", :erb))
    end

    assert_equal(1, events.size)
    assert_equal("boom", events.first.payload[:error].message)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
