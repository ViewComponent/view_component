require "spec_helper"

RSpec.feature "Feature specs for isolated view components" do
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
end
