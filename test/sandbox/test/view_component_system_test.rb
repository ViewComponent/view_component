# frozen_string_literal: true

require "test_helper"

class ViewComponentSystemTest < ViewComponent::SystemTestCase
  driven_by :cuprite

  def test_simple_js_interaction_in_browser_without_layout
    with_rendered_component_path(SimpleJavascriptInteractionWithJsIncludedComponent.new) do |page|
      visit page

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end

  def test_simple_js_interaction_in_browser_with_layout
    with_rendered_component_path(SimpleJavascriptInteractionWithoutJsIncludedComponent.new, layout: "application") do |page|
      visit page

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end

  def test_component_with_params
    with_rendered_component_path(TitleWrapperComponent.new(title: "awesome-title")) do |page|
      visit page

      assert find('div', text: 'awesome-title')
    end
  end

end
