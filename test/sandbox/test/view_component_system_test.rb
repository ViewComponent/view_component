# frozen_string_literal: true

require "test_helper"

class ViewComponentSystemTest < ViewComponent::SystemTestCase
  driven_by :cuprite

  def test_simple_js_interaction_in_browser_without_layout
    inline_component = render_inline(SimpleJavascriptInteractionWithJsIncludedComponent.new)

    with_inline_rendered_component_path(inline_component) do |path|
      visit path

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end

  def test_simple_js_interaction_in_browser_with_layout
    inline_component = render_inline(SimpleJavascriptInteractionWithoutJsIncludedComponent.new)
    
    with_inline_rendered_component_path(inline_component, layout: 'application') do |path|
      visit path

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end

  def test_component_with_params
    inline_component = render_inline(TitleWrapperComponent.new(title: "awesome-title"))

    with_inline_rendered_component_path(inline_component) do |path|
      visit path

      assert find('div', text: 'awesome-title')
    end
  end

  def test_components_with_slots
    inline_component = render_inline(SlotsV2Component.new) do |component|
      component.title do
        "This is my title!"
      end
    end

    with_inline_rendered_component_path(inline_component) do |path|
      visit path

      find('.title', text: 'This is my title!')
    end
  end
end
