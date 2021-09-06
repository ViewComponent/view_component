# frozen_string_literal: true

require "test_helper"

class ViewComponentSystemTest < ViewComponent::SystemTestCase
  driven_by :cuprite

  def test_simple_js_interaction_in_browser
    visit_rendered_in_browser(SimpleJavascriptInteractionComponent.new, layout: "application")

    assert find("[data-hidden-field]", visible: false)
    find("[data-button]", text: "Click Me To Reveal Something Cool").click
    assert find("[data-hidden-field]", visible: true)
  end
end
