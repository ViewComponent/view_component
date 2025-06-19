require "spec_helper"

RSpec.describe "System specs for isolated view components", type: :system do
  before do
    driven_by(:rack_test)
  end

  scenario "page is a Capybara::Session" do
    expect(page).to be_a Capybara::Session
  end

  scenario "page responds to visit" do
    expect(page).to respond_to :visit
  end

  scenario "visit the isolated, rendered component" do
    with_rendered_component_path(render_inline(MyComponent.new)) do |path|
      visit(path)
    end
  end

  def page
    Capybara.current_session
  end
end
