# frozen_string_literal: true

require "test_helper"

class ViewComponentBrowserTest < ViewComponent::BrowserTestCase
  if Rails.version.to_f >= 6.1
    def test_simple_js_interaction_in_browser_with_layout
      render_in_browser(SimpleJavascriptInteractionComponent.new, layout: "application")

      # Assert layout is included
      assert page.body.include?("<title>ViewComponent - Test</title>")

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end

  def test_simple_js_interaction_in_browser_without_layout
    render_in_browser(SimpleJavascriptInteractionComponent.new)

    # Assert layout is NOT included
    refute page.body.include?("<title>ViewComponent - Test</title>")

    assert find("[data-hidden-field]", visible: false)
    find("[data-button]", text: "Click Me To Reveal Something Cool").click
    assert find("[data-hidden-field]", visible: true)
  end
end
