# frozen_string_literal: true

require "test_helper"

class ViewComponentSystemTest < ViewComponent::SystemTestCase
  driven_by :cuprite

  def test_simple_js_interaction_in_browser_without_layout
    fragment = render_inline(SimpleJavascriptInteractionWithJsIncludedComponent.new)

    with_rendered_component_path(fragment) do |path|
      visit path

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end

  def test_simple_js_interaction_in_browser_with_layout
    fragment = render_inline(SimpleJavascriptInteractionWithoutJsIncludedComponent.new)
    
    with_rendered_component_path(fragment, layout: 'application') do |path|
      visit path

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end

  def test_component_with_params
    fragment = render_inline(TitleWrapperComponent.new(title: "awesome-title"))

    with_rendered_component_path(fragment) do |path|
      visit path

      assert find('div', text: 'awesome-title')
    end
  end

  def test_components_with_slots
    fragment = render_inline(SlotsV2Component.new) do |component|
      component.title do
        "This is my title!"
      end
    end

    with_rendered_component_path(fragment) do |path|
      visit path

      find('.title', text: 'This is my title!')
    end
  end
end
