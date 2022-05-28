# frozen_string_literal: true

require "test_helper"

class ViewComponentSystemTest < ViewComponent::SystemTestCase
  driven_by :cuprite

  def test_protection_unauthorized_access_in_production_env
    mock = Minitest::Mock.new
    mock.expect :production?, true
    mock.expect :development?, false
    mock.expect :test?, false

    Rails.stub :env, mock do
      visit_rendered_component_in_browser(
        SimpleJavascriptInteractionWithJsIncludedComponent.new
      )

      assert_text "Unauthorized"
    end
  end

  def test_simple_js_interaction_in_browser_without_layout
    visit_rendered_component_in_browser(
      SimpleJavascriptInteractionWithJsIncludedComponent.new
    )

    assert find("[data-hidden-field]", visible: false)
    find("[data-button]", text: "Click Me To Reveal Something Cool").click
    assert find("[data-hidden-field]", visible: true)
  end

  def test_simple_js_interaction_in_browser_with_layout
    visit_rendered_component_in_browser(
      SimpleJavascriptInteractionWithoutJsIncludedComponent.new,
      layout: "application"
    )

    assert find("[data-hidden-field]", visible: false)
    find("[data-button]", text: "Click Me To Reveal Something Cool").click
    assert find("[data-hidden-field]", visible: true)
  end
end
