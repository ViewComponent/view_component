# frozen_string_literal: true

require "test_helper"

class ContextualTest < ViewComponent::TestCase
  def test_table_like_component
    data = [
      {id: 1, foo: "foo-1", bar: "bar-1"},
      {id: 2, foo: "foo-2", bar: "bar-2"}
    ]

    render_inline(ContextualTableComponent.new(data: data)) do |component|
      component.column :foo, label: "Foo"
      component.column label: "Bar" do |col|
        "item #{ col.item[:bar] }"
      end
      component.column :bar, label: "Bar directly" do |col|
        "value #{ col.value }"
      end
    end

    assert_selector 'thead th[data-field="foo"]', text: "Foo"

    assert_selector 'tbody tr[data-id="1"] td[data-field="foo"]', text: "foo-1"
    assert_selector 'tbody tr[data-id="1"] td[data-field=""]', text: "item bar-1"
    assert_selector 'tbody tr[data-id="1"] td[data-field="bar"]', text: "value bar-1"
    assert_selector 'tbody tr[data-id="2"] td[data-field="bar"]', text: "value bar-2"
  end

  def test_paginator_like_component
    render_inline(ContextualPaginatorComponent.new(max: 10, current: 5)) do |component|
      component.current_page do |page|
        "current #{ page.number }"
      end

      component.page do |page|
        "page #{ page.number }"
      end
    end

    assert_selector %(ul li[data-page="1"]), text: "page 1"
    assert_selector %(ul li[data-page="2"]), text: "page 2"
    assert_selector %(ul li[data-page="5"]), text: "current 5"
  end
end
