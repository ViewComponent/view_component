# frozen_string_literal: true

require "test_helper"
require "view_component/attributes"

class AttributesTest < ViewComponent::TestCase
  class MyAttributeComponent < ViewComponent::Base
    include ViewComponent::Attributes

    accepts :title, required: true
    accepts :body
    accepts :posted_at, default: Date.today

    def call
      content_tag :div do
        safe_join([
          content_tag(:h1, @title),
          content_tag(:p, @body),
          content_tag(:date, @posted_at),
        ])
      end
    end
  end

  class MyInheritedAttributeComponent < MyAttributeComponent
  end

  def test_basic_attributes
    render_inline MyAttributeComponent.new(title: "foo")

    assert_selector('h1', text: 'foo')
  end

  def test_required_attribute_raises_if_missing
    assert_raises ArgumentError do
      render_inline MyAttributeComponent.new
    end
  end

  def test_optional_arguments_default_to_nil
    component = MyAttributeComponent.new(title: "foo")
    assert_nil component.body
  end

  def test_default_values_are_set_if_argument_is_missing
    freeze_time do
      component = MyAttributeComponent.new(title: "foo")
      assert_equal Date.today, component.posted_at
    end
  end

  def test_explicit_nil_overrides_default_values
    component = MyAttributeComponent.new(title: "foo", posted_at: nil)
    assert_nil component.posted_at
  end

  def test_inheritance_works
    render_inline MyInheritedAttributeComponent.new(title: "foo")

    assert_selector('h1', text: 'foo')
  end
end
