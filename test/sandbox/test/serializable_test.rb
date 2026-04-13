# frozen_string_literal: true

require "test_helper"

class SerializableTest < ViewComponent::TestCase
  def test_serializable_returns_component_instance
    component = SerializableComponent.serializable(title: "Hello", count: 5)
    assert_kind_of SerializableComponent, component
  end

  def test_serializable_stores_kwargs
    component = SerializableComponent.serializable(title: "Hello", count: 5)
    assert_equal({title: "Hello", count: 5}, component.serializable_kwargs)
  end

  def test_new_does_not_set_serializable_kwargs
    component = SerializableComponent.new(title: "Hello")
    assert_nil component.serializable_kwargs
  end

  def test_serializable_component_renders
    result = render_inline(SerializableComponent.serializable(title: "Test", count: 3))
    assert_includes result.to_html, "Test"
    assert_includes result.to_html, "3"
  end

  def test_serializable_with_default_kwargs
    component = SerializableComponent.serializable(title: "Defaults")
    assert_equal({title: "Defaults"}, component.serializable_kwargs)

    result = render_inline(component)
    assert_includes result.to_html, "Defaults"
    assert_includes result.to_html, "0"
  end

  def test_serializable_not_available_without_concern
    assert_raises(NoMethodError) do
      MyComponent.serializable(message: "nope")
    end
  end
end

class SerializableSerializerTest < ActiveSupport::TestCase
  def setup
    @serializer = ViewComponent::SerializableSerializer.instance
  end

  def test_serialize_predicate_true_for_serializable_instance
    component = SerializableComponent.serializable(title: "Hi", count: 1)
    assert @serializer.serialize?(component)
  end

  def test_serialize_predicate_true_for_new_instance_with_concern
    component = SerializableComponent.new(title: "Hi")
    assert @serializer.serialize?(component)
  end

  def test_serialize_raises_for_new_instance
    component = SerializableComponent.new(title: "Hi")
    error = assert_raises(ArgumentError) { @serializer.serialize(component) }
    assert_includes error.message, ".serializable"
    assert_includes error.message, "SerializableComponent"
  end

  def test_serialize_predicate_false_for_non_component
    refute @serializer.serialize?("not a component")
  end

  def test_round_trip_serialization
    original = SerializableComponent.serializable(title: "Round Trip", count: 42)
    serialized = @serializer.serialize(original)
    deserialized = @serializer.deserialize(serialized)

    assert_kind_of SerializableComponent, deserialized
    assert_equal({title: "Round Trip", count: 42}, deserialized.serializable_kwargs)
  end

  def test_round_trip_with_default_kwargs
    original = SerializableComponent.serializable(title: "Defaults Only")
    serialized = @serializer.serialize(original)
    deserialized = @serializer.deserialize(serialized)

    assert_equal({title: "Defaults Only"}, deserialized.serializable_kwargs)
  end

  def test_serialized_format
    component = SerializableComponent.serializable(title: "Format", count: 9)
    serialized = @serializer.serialize(component)

    assert_equal "SerializableComponent", serialized["component"]
    assert serialized.key?("kwargs")
  end

  def test_deserialize_unknown_component_raises
    assert_raises(ArgumentError) do
      @serializer.deserialize({"component" => "NonExistentComponent", "kwargs" => []})
    end
  end
end

class SerializableTurboStreamTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  def test_broadcast_action_later_with_serializable_component
    component = SerializableComponent.serializable(title: "Broadcast Test", count: 7)

    assert_turbo_stream_broadcasts("serializable_test_stream") do
      Turbo::StreamsChannel.broadcast_action_later_to(
        "serializable_test_stream",
        action: :replace,
        target: "my-target",
        renderable: component,
        layout: false
      )
      perform_enqueued_jobs
    end

    broadcasts = capture_turbo_stream_broadcasts("serializable_test_stream")
    assert_equal "replace", broadcasts.first["action"]
    assert_equal "my-target", broadcasts.first["target"]
    assert_includes broadcasts.first.to_html, "Broadcast Test"
    assert_includes broadcasts.first.to_html, "7"
  end
end
