# frozen_string_literal: true

require "test_helper"

class DelegateSlotsTest < ViewComponent::TestCase
  def test_delegates_slots
    render_inline(DelegatedSlotsChildComponent.new) do |c|
      c.header(text: "Header")
      c.item(text: "Item 1")
      c.item(text: "Item 2")
    end

    assert_selector "p.color-red", text: "Header"
    assert_selector "li.color-green", text: "Item 1"
    assert_selector "li.color-green", text: "Item 2"
  end

  def test_can_get_renders_one_slot
    render_inline(component = DelegatedSlotsChildComponent.new) do |c|
      c.header(text: "Header")
      c.item(text: "Item 1")
      c.item(text: "Item 2")
    end

    assert component.header
  end

  def test_can_get_renders_many_slot
    render_inline(component = DelegatedSlotsChildComponent.new) do |c|
      c.header(text: "Header")
      c.item(text: "Item 1")
      c.item(text: "Item 2")
    end

    assert component.items.size == 2
  end

  def test_delegates_slots_through_two_nesting_levels
    render_inline(DelegatedSlotsGrandchildComponent.new) do |c|
      c.header(text: "Header")
      c.item(text: "Item 1")
      c.item(text: "Item 2")
    end

    assert_selector "p.color-blue", text: "Header"
    assert_selector "li.color-yellow", text: "Item 1"
    assert_selector "li.color-yellow", text: "Item 2"
  end

  def test_can_get_renders_one_slot_through_two_nesting_levels
    render_inline(component = DelegatedSlotsGrandchildComponent.new) do |c|
      c.header(text: "Header")
      c.item(text: "Item 1")
      c.item(text: "Item 2")
    end

    assert component.header
  end

  def test_can_get_renders_many_slot_through_two_nesting_levels
    render_inline(component = DelegatedSlotsGrandchildComponent.new) do |c|
      c.header(text: "Header")
      c.item(text: "Item 1")
      c.item(text: "Item 2")
    end

    assert component.items.size == 2
  end
end
