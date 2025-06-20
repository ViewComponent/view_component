require "spec_helper"

RSpec.describe "System specs for isolated view components", type: :system do
  before do
    driven_by(:system_test_driver)
  end

  scenario "page is a Capybara::Session" do
    expect(page).to be_a Capybara::Session
  end

  scenario "page responds to visit" do
    expect(page).to respond_to :visit
  end

  scenario "visit the isolated, rendered component" do
    with_rendered_component_path(render_inline(SimpleJavascriptInteractionWithJsIncludedComponent.new)) do |path|
      visit path

      assert find("[data-hidden-field]", visible: false)
      find("[data-button]", text: "Click Me To Reveal Something Cool").click
      assert find("[data-hidden-field]", visible: true)
    end
  end
end
