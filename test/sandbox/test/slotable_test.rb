# frozen_string_literal: true

require "test_helper"

class SlotableTest < ViewComponent::TestCase
  def test_renders_slots
    render_inline(SlotsComponent.new(classes: "mt-4")) do |component|
      component.with_title do
        "This is my title!"
      end
      component.with_subtitle do
        "This is my subtitle!"
      end

      component.with_tab do
        "Tab A"
      end
      component.with_tab do
        "Tab B"
      end

      component.with_item do
        "Item A"
      end
      component.with_item(highlighted: true) do
        "Item B"
      end
      component.with_item do
        "Item C"
      end

      component.with_footer(classes: "text-blue") do
        "This is the footer"
      end
    end

    assert_selector(".card.mt-4")

    assert_selector(".title", text: "This is my title!")

    assert_selector(".subtitle", text: "This is my subtitle!")

    assert_selector(".tab", text: "Tab A")
    assert_selector(".tab", text: "Tab B")

    assert_selector(".item", count: 3)
    assert_selector(".item.highlighted", count: 1)
    assert_selector(".item.normal", count: 2)

    assert_selector(".footer.text-blue")
  end

  def test_renders_slots_in_inherited_components
    render_inline(InheritedSlotsComponent.new(classes: "mt-4")) do |component|
      component.with_title do
        "This is my title!"
      end
      component.with_subtitle do
        "This is my subtitle!"
      end

      component.with_tab do
        "Tab A"
      end
      component.with_tab do
        "Tab B"
      end

      component.with_item do
        "Item A"
      end
      component.with_item(highlighted: true) do
        "Item B"
      end
      component.with_item do
        "Item C"
      end

      component.with_footer(classes: "text-blue") do
        "This is the footer"
      end
    end

    assert_selector(".card.mt-4")

    assert_selector(".title", text: "This is my title!")

    assert_selector(".subtitle", text: "This is my subtitle!")

    assert_selector(".tab", text: "Tab A")
    assert_selector(".tab", text: "Tab B")

    assert_selector(".item", count: 3)
    assert_selector(".item.highlighted", count: 1)
    assert_selector(".item.normal", count: 2)

    assert_selector(".footer.text-blue", text: "This is the footer")
  end

  def test_renders_slots_with_empty_collections
    render_inline(SlotsComponent.new) do |component|
      component.with_title do
        "This is my title!"
      end

      component.with_subtitle do
        "This is my subtitle!"
      end

      component.with_footer do
        "This is the footer"
      end
    end

    assert_text "No tabs provided"
    assert_text "No items provided"
  end

  def test_renders_slots_template_raise_with_unknown_slot
    assert_raises NoMethodError do
      render_inline(SlotsComponent.new) do |component|
        component.with_foo { "Hello!" }
      end
    end
  end

  def test_sub_component_raise_with_duplicate_slot_name
    exception =
      assert_raises ArgumentError do
        SlotsComponent.renders_one :title
      end

    assert_includes exception.message, "declares the title slot multiple times"
  end

  def test_sub_component_with_positional_args
    render_inline(SlotsWithPosArgComponent.new(classes: "mt-4")) do |component|
      component.with_item("my item", classes: "hello") { "My rad item" }
    end

    assert_selector(".item", text: "my item")
    assert_selector(".item-content", text: "My rad item")
  end

  def test_sub_component_template_rendering
    render_inline(Nested::SlotsComponent.new) do |component|
      component.with_item do |sub_component|
        sub_component.with_thing do
          "My rad thing"
        end
      end
    end

    assert_selector(".thing", text: "My rad thing")
  end

  def test_slot_with_component_delegate
    render_inline SlotsDelegateComponent.new do |component|
      component.with_item do
        "Item A"
      end
      component.with_item(highlighted: true) do
        "Item B"
      end
      component.with_item do
        "Item C"
      end
    end

    assert_selector(".item", count: 3)
    assert_selector(".item.highlighted", count: 1)
    assert_selector(".item.normal", count: 2)
  end

  def test_slot_with_respond_to
    component = SlotsDelegateComponent.new

    render_inline component do |c|
      c.with_item do
        "Item A"
      end
    end

    assert component.items.first.respond_to?(:classes)
  end

  def test_slot_forwards_kwargs_to_component
    component = SlotsComponent.new

    render_inline component do |c|
      c.with_item do
        "Item A"
      end
    end

    assert_equal component.items.first.method_with_kwargs(**{foo: :bar}), {foo: :bar}
  end

  def test_slot_with_collection
    render_inline SlotsDelegateComponent.new do |component|
      component.with_items([{highlighted: false}, {highlighted: true}, {highlighted: false}]) do
        "My Item"
      end
    end

    assert_selector(".item", count: 3, text: "My Item")
    assert_selector(".item.highlighted", count: 1)
    assert_selector(".item.normal", count: 2)
  end

  def test_slot_with_collection_returns_slots
    render_inline SlotsDelegateComponent.new do |component|
      component.with_items([{highlighted: false}, {highlighted: true}, {highlighted: false}])
        .each_with_index do |slot, index|
          slot.with_content("My Item #{index + 1}")
        end
    end

    assert_selector(".item", count: 1, text: "My Item 1")
    assert_selector(".item", count: 1, text: "My Item 2")
    assert_selector(".item", count: 1, text: "My Item 3")
    assert_selector(".item.highlighted", count: 1)
    assert_selector(".item.normal", count: 2)
  end

  def test_renders_nested_content_in_order
    render_inline TitleWrapperComponent.new(title: "Hello world!")

    assert_selector("h1", text: /Hello world/)
    assert_text(/Hello world/, count: 1)
  end

  # In a previous implementation of slots,
  # the list of slots registered to a component
  # was accidentally assigned to all components!
  def test_sub_components_pollution
    new_component_class = Class.new(ViewComponent::Base)
    # this returned:
    # [SlotsComponent::Subtitle, SlotsComponent::Tab...]
    assert_empty new_component_class.registered_slots
  end

  def test_renders_slots_with_before_render_hook
    render_inline(SlotsBeforeRenderComponent.new) do |component|
      component.with_title do
        "This is my title!"
      end

      component.with_greeting do
        "John Doe"
      end
      component.with_greeting do
        "Jane Doe"
      end
    end

    assert_selector("h1", text: "Testing - This is my title!")
    assert_selector(".greeting", text: "Hello, John Doe")
    assert_selector(".greeting", text: "Hello, Jane Doe")
  end

  def test_slots_accessible_in_render_predicate
    render_inline(SlotsRenderPredicateComponent.new) do |component|
      component.with_title do
        "This is my title!"
      end
    end

    assert_selector("h1", text: "This is my title!")
  end

  def test_slots_without_render_block
    render_inline(SlotsWithoutContentBlockComponent.new) do |component|
      component.with_title(title: "This is my title!")
    end

    assert_selector("h1", text: "This is my title!")
  end

  def test_slot_with_block_content
    render_inline(SlotsBlockComponent.new)

    assert_selector("p", text: "Footer part 1")
    assert_selector("p", text: "Footer part 2")
  end

  def test_lambda_slot_with_missing_block
    render_inline(SlotsComponent.new(classes: "mt-4")) do |component|
      component.with_footer(classes: "text-blue")
    end
  end

  def test_slot_with_nested_blocks_content_selectable_true
    render_inline(NestedSharedState::TableComponent.new(selectable: true)) do |table_card|
      table_card.with_header(
        "regular_argument",
        class_names: "table__header extracted_kwarg",
        data: {splatted_kwarg: "splatted_keyword_argument"}
      ) do |header|
        header.with_cell { "Cell1" }
        header.with_cell(class_names: "-has-sort") { "Cell2" }
      end
    end

    assert_selector("div.table div.table__header div.table__cell", text: "Cell1")
    assert_selector("div.table div.table__header div.table__cell.-has-sort", text: "Cell2")

    # Check shared data through Proc
    assert_selector("div.table div.table__header span", text: "Selectable")

    # Check regular arguments
    assert_selector('div.table div.table__header[data-argument="regular_argument"]')

    # Check extracted keyword argument
    assert_selector("div.table div.table__header.extracted_kwarg")

    # Check splatted keyword arguments
    assert_selector('div.table div.table__header[data-splatted-kwarg="splatted_keyword_argument"]')
  end

  def test_slot_with_nested_blocks_content_selectable_false
    render_inline(NestedSharedState::TableComponent.new(selectable: false)) do |table_card|
      table_card.with_header do |header|
        header.with_cell { "Cell1" }
        header.with_cell(class_names: "-has-sort") { "Cell2" }
      end
    end

    assert_selector("div.table div.table__header div.table__cell", text: "Cell1")
    assert_selector("div.table div.table__header div.table__cell.-has-sort", text: "Cell2")

    # Check shared data through Proc
    refute_selector("div.table div.table__header span", text: "Selectable")
  end

  def test_component_raises_when_given_content_slot_name
    exception =
      assert_raises ArgumentError do
        Class.new(ViewComponent::Base) do
          renders_one :content
        end
      end

    assert_includes exception.message, "declares a slot named content"
    assert_includes exception.message, "without having to create"
  end

  def test_component_raises_when_given_invalid_slot_name
    exception =
      assert_raises ArgumentError do
        Class.new(ViewComponent::Base) do
          renders_one :render
        end
      end

    assert_includes exception.message, "declares a slot named render"
  end

  def test_component_raises_when_given_one_slot_name_ending_with_question_mark
    exception =
      assert_raises ArgumentError do
        Class.new(ViewComponent::Base) do
          renders_one :item?
        end
      end

    assert_includes exception.message, "declares a slot named item?, which ends with a question mark"
  end

  def test_component_raises_when_given_invalid_slot_name_for_has_many
    exception = assert_raises ArgumentError do
      Class.new(ViewComponent::Base) do
        renders_many :contents
      end
    end

    assert_includes exception.message, "declares a slot named contents"
  end

  def test_component_raises_when_given_many_slot_name_ending_with_question_mark
    exception =
      assert_raises ArgumentError do
        Class.new(ViewComponent::Base) do
          renders_many :items?
        end
      end

    assert_includes exception.message, "declares a slot named items?, which ends with a question mark"
  end

  def test_renders_pass_through_slot_using_with_content
    component = SlotsComponent.new
    component.with_title("some_argument").with_content("This is my title!")

    render_inline(component)
    assert_selector(".title", text: "This is my title!")
  end

  def test_renders_lambda_slot_using_with_content
    component = SlotsComponent.new
    component.with_item(highlighted: false).with_content("This is my item!")

    render_inline(component)
    assert_selector(".item.normal", text: "This is my item!")
  end

  def test_renders_component_slot_using_with_content
    component = SlotsComponent.new
    component.with_extra(message: "My message").with_content("This is my content!")

    render_inline(component)
    assert_selector(".extra") do
      assert_text("This is my content!")
      assert_text("My message")
    end
  end

  def test_raises_if_using_both_block_content_and_with_content
    error =
      assert_raises ArgumentError do
        component = SlotsComponent.new
        slot = component.with_title("some_argument")
        slot.with_content("This is my title!")
        slot.__vc_content_block = "some block"

        render_inline(component)
      end

    assert_includes error.message, "It looks like a block was provided after calling"
  end

  def test_renders_lambda_slot_with_no_args
    render_inline(SlotsWithEmptyLambdaComponent.new) do |component|
      component.with_item { "Item 1" }
      component.with_item { "Item 2" }
      component.with_item { "Item 3" }
    end

    assert_selector(".item") do
      assert_selector("h1", text: "Title 1")
      assert_selector(".item-content", text: "Item 1")
    end
    assert_selector(".item") do
      assert_selector("h1", text: "Title 2")
      assert_selector(".item-content", text: "Item 2")
    end
    assert_selector(".item") do
      assert_selector("h1", text: "Title 3")
      assert_selector(".item-content", text: "Item 3")
    end
  end

  def test_supports_with_setters
    render_inline(SlotsComponent.new(classes: "mt-4")) do |component|
      component.with_title.with_content("This is my title!")
      component.with_subtitle.with_content("This is my subtitle!")
      component.with_tab.with_content("Tab A")
      component.with_tab.with_content("Tab B")
      component.with_item.with_content("Item A")
      component.with_item(highlighted: true).with_content("Item B")
      component.with_item.with_content("Item C")

      component.with_footer(classes: "text-blue") do
        "This is the footer"
      end
    end

    assert_selector(".card.mt-4")

    assert_selector(".title", text: "This is my title!")

    assert_selector(".subtitle", text: "This is my subtitle!")

    assert_selector(".tab", text: "Tab A")
    assert_selector(".tab", text: "Tab B")

    assert_selector(".item", count: 3)
    assert_selector(".item.highlighted", count: 1)
    assert_selector(".item.normal", count: 2)

    assert_selector(".footer.text-blue")
  end

  def test_supports_with_setters_plural
    render_inline(SlotsComponent.new(classes: "mt-4")) do |component|
      component.with_items([{highlighted: true}, {highlighted: false}])
    end

    assert_selector(".item", count: 2)
    assert_selector(".item.highlighted", count: 1)
  end

  def test_polymorphic_slot_with_setters
    render_inline(PolymorphicSlotComponent.new) do |component|
      component.with_header_standard { "standard" }
      component.with_item_foo(class_names: "custom-foo")
      component.with_item_bar(class_names: "custom-bar")
    end

    assert_selector("div .standard", text: "standard")
    assert_selector("div .foo.custom-foo:nth-child(2)")
    assert_selector("div .bar.custom-bar:last")
  end

  def test_polymorphic_slot_predicate
    render_inline(PolymorphicSlotComponent.new) do |component|
      component.with_item_foo(class_names: "custom-foo")
      component.with_item_bar(class_names: "custom-bar")
    end

    assert_no_selector("div#header")
  end

  def test_supports_with_collection_setter
    render_inline(SlotsComponent.new(classes: "mt-4")) do |component|
      component.with_items([{}, {highlighted: true}, {}])
    end

    assert_selector(".item", count: 3)
    assert_selector(".item.highlighted", count: 1)
  end

  def test_slot_type_single
    assert_equal(:single, SlotsComponent.slot_type(:title))
  end

  def test_slot_type_collection
    assert_equal(:collection, SlotsComponent.slot_type(:tabs))
  end

  def test_slot_type_collection_item?
    assert_equal(:collection_item, SlotsComponent.slot_type(:tab))
  end

  def test_slot_type_nil?
    assert_nil(SlotsComponent.slot_type(:junk))
  end

  def test_polymorphic_slot
    render_inline(PolymorphicSlotComponent.new) do |component|
      component.with_header_standard { "standard" }
      component.with_item_foo(class_names: "custom-foo")
      component.with_item_bar(class_names: "custom-bar")
    end

    assert_selector("div .standard", text: "standard")
    assert_selector("div .foo.custom-foo:nth-child(2)")
    assert_selector("div .bar.custom-bar:last")
  end

  def test_polymorphic_slot_non_member
    assert_raises NoMethodError do
      render_inline(PolymorphicSlotComponent.new) do |component|
        component.with_item_non_existent
      end
    end
  end

  def test_singular_polymorphic_slot_raises_on_redefinition
    error = assert_raises ArgumentError do
      render_inline(PolymorphicSlotComponent.new) do |component|
        component.with_header_standard { "standard" }
        component.with_header_special { "special" }
      end
    end

    assert_includes error.message, "has already been provided"
  end

  def test_invalid_slot_definition_raises_error
    error = assert_raises ArgumentError do
      Class.new(ViewComponent::Base) do
        renders_many :items, :foo
      end
    end

    assert_includes error.message, "invalid slot definition"
  end

  def test_component_delegation_slots_work_with_helpers
    PartialHelper::State.reset

    assert_nothing_raised do
      render_inline WrapperComponent.new do |wrapper|
        wrapper.render(PartialSlotHelperComponent.new) do |component|
          component.with_header {}
        end
      end
    end

    assert_equal 1, PartialHelper::State.calls
  end

  def test_lambda_slot_content_can_be_provided_via_a_block
    render_inline LambdaSlotComponent.new do |component|
      component.with_header(classes: "some-class") do
        "This is a header!"
      end
    end

    assert_selector("h1.some-class", text: "This is a header!")
  end

  def test_raises_error_on_conflicting_slot_names
    error = assert_raises ArgumentError do
      Class.new(ViewComponent::Base) do
        renders_one :conflicting_item
        renders_many :conflicting_items
      end
    end

    assert_includes error.message, "conflicting_item slot multiple times"
  end

  def test_raises_error_on_conflicting_slot_names_in_reverse_order
    error = assert_raises ArgumentError do
      Class.new(ViewComponent::Base) do
        renders_many :conflicting_items
        renders_one :conflicting_item
      end
    end

    assert_includes error.message, "conflicting_items slot multiple times"
  end

  def test_slots_dont_interfere_with_content
    render_inline(PolymorphicWrapperComponent.new) do |c|
      c.section
    end

    assert_selector(".label", text: "the truth is out there")
  end
end
