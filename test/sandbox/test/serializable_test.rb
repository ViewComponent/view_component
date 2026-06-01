# frozen_string_literal: true

require "test_helper"

class SerializableProxyTest < ViewComponent::TestCase
  def test_render_later_returns_proxy
    proxy = SerializableComponent.render_later("Hello", count: 5)
    assert_kind_of ViewComponent::Serializable::Proxy, proxy
  end

  def test_proxy_stores_component_class
    proxy = SerializableComponent.render_later("Hello")
    assert_equal SerializableComponent, proxy.component_class
  end

  def test_proxy_stores_initialize_args_positional_only
    proxy = SerializableComponent.render_later("Hello")
    assert_equal ["Hello"], proxy.initialize_args
  end

  def test_proxy_stores_initialize_args_mixed
    proxy = SerializableComponent.render_later("Hello", count: 5)
    assert_equal ["Hello", {count: 5}], proxy.initialize_args
  end

  def test_proxy_renders
    proxy = SerializableComponent.render_later("Rendered", count: 3)
    result = render_inline(proxy)
    assert_includes result.to_html, "Rendered"
    assert_includes result.to_html, "3"
  end

  def test_proxy_with_default_kwargs
    proxy = SerializableComponent.render_later("Defaults Only")
    result = render_inline(proxy)
    assert_includes result.to_html, "Defaults Only"
    assert_includes result.to_html, "0"
  end

  def test_proxy_with_positional_args_renders
    proxy = SerializableComponent.render_later("Positional", count: 7)
    result = render_inline(proxy)
    assert_includes result.to_html, "Positional"
    assert_includes result.to_html, "7"
  end

  def test_proxy_captures_slot_calls
    proxy = SerializableComponent.render_later("Slots")
    proxy.with_header(text: "My Header")
    assert_equal 1, proxy.slot_calls.length
    assert_equal :with_header, proxy.slot_calls.first[:method]
  end

  def test_proxy_slot_calls_are_replayed_at_render
    proxy = SerializableComponent.render_later("Slotted")
    proxy.with_header(text: "Header Content")
    proxy.with_item("Item One")
    proxy.with_item("Item Two")
    result = render_inline(proxy)
    assert_includes result.to_html, "Slotted"
    assert_includes result.to_html, "Header Content"
    assert_includes result.to_html, "Item One"
    assert_includes result.to_html, "Item Two"
  end

  def test_proxy_slot_call_with_kwargs
    proxy = SerializableComponent.render_later("Kwarg Slots")
    proxy.with_item("Label", highlighted: true)
    assert_equal ["Label", {highlighted: true}], proxy.slot_calls.first[:args]
  end

  def test_proxy_is_not_a_component_instance
    proxy = SerializableComponent.render_later("Proxy")
    refute_kind_of ViewComponent::Base, proxy
  end

  def test_proxy_only_captures_real_slot_methods
    proxy = SerializableComponent.render_later("Real Slots")
    refute_respond_to proxy, :with_indifferent_access
    assert_raises(NoMethodError) { proxy.with_nonexistent_slot }
    assert_empty proxy.slot_calls
  end

  def test_render_in_with_block_raises
    proxy = SerializableComponent.render_later("Block Render")
    assert_raises(ViewComponent::Serializable::UnserializableError) do
      render_inline(proxy) { "content" }
    end
  end

  def test_block_slot_calls_raise_immediately
    proxy = SerializableComponent.render_later("Blocks")
    error = assert_raises(ViewComponent::Serializable::UnserializableError) do
      proxy.with_header { "Header" }
    end
    assert_includes error.message, "with_header"
    assert_includes error.message, "block"
    assert_empty proxy.slot_calls
  end

  def test_unserializable_error_is_argument_error
    assert ViewComponent::Serializable::UnserializableError < ArgumentError
  end

  def test_render_later_requires_include
    assert_respond_to SerializableComponent, :render_later
    refute_respond_to MyComponent, :render_later
  end
end

class ActiveJobSerializerTest < ActiveSupport::TestCase
  def setup
    @serializer = ViewComponent::ActiveJobSerializer.instance
  end

  def test_serializes_proxy
    proxy = SerializableComponent.render_later("Hi", count: 1)
    assert @serializer.serialize?(proxy)
  end

  def test_does_not_serialize_plain_objects
    refute @serializer.serialize?("not a proxy")
    refute @serializer.serialize?(SerializableComponent.new("direct"))
  end

  def test_round_trip_positional_args
    original = SerializableComponent.render_later("Round Trip", count: 42)
    serialized = @serializer.serialize(original)
    deserialized = @serializer.deserialize(serialized)

    assert_kind_of ViewComponent::Serializable::Proxy, deserialized
    assert_equal SerializableComponent, deserialized.component_class
    assert_equal ["Round Trip", {count: 42}], deserialized.initialize_args
  end

  def test_round_trip_with_slot_kwargs
    original = SerializableComponent.render_later("With Slots")
    original.with_item("Label", highlighted: true)

    serialized = @serializer.serialize(original)
    deserialized = @serializer.deserialize(serialized)

    assert_equal 1, deserialized.slot_calls.length
    assert_equal :with_item, deserialized.slot_calls.first[:method]
    assert_equal ["Label", {highlighted: true}], deserialized.slot_calls.first[:args]
  end

  def test_round_trip_with_slot_positional_args
    original = SerializableComponent.render_later("Positional")
    original.with_item("some string")

    serialized = @serializer.serialize(original)
    deserialized = @serializer.deserialize(serialized)

    assert_equal 1, deserialized.slot_calls.length
    assert_equal ["some string"], deserialized.slot_calls.first[:args]
  end

  def test_serialized_format_keys
    proxy = SerializableComponent.render_later("Format", count: 9)
    serialized = @serializer.serialize(proxy)

    assert_equal "SerializableComponent", serialized["component_class"]
    assert serialized.key?("initialize_args")
    assert serialized.key?("slot_calls")
    assert_equal [], serialized["slot_calls"]
  end

  def test_deserialize_unknown_component_raises
    assert_raises(ArgumentError) do
      @serializer.deserialize({"component_class" => "NonExistentComponent", "initialize_args" => [], "slot_calls" => []})
    end
  end
end

class RenderLaterTurboStreamTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  def test_broadcast_action_later_with_render_later_proxy
    proxy = SerializableComponent.render_later("Broadcast Test", count: 7)

    assert_turbo_stream_broadcasts("render_later_test_stream") do
      Turbo::StreamsChannel.broadcast_action_later_to(
        "render_later_test_stream",
        action: :replace,
        target: "my-target",
        renderable: proxy,
        layout: false
      )
      perform_enqueued_jobs
    end

    broadcasts = capture_turbo_stream_broadcasts("render_later_test_stream")
    assert_equal "replace", broadcasts.first["action"]
    assert_equal "my-target", broadcasts.first["target"]
    assert_includes broadcasts.first.to_html, "Broadcast Test"
    assert_includes broadcasts.first.to_html, "7"
  end
end
