# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActionDispatch::IntegrationTest
  test "rendering component in a view" do
    get "/"
    assert_response :success
    assert_html_matches <<~HTML, response.body
      <span><div>
        Foo
        bar
      </div>
      </span>
    HTML
  end

  test "rendering component with content" do
    get "/content"
    assert_response :success
    assert_select "div.State--green"
    assert_select "div[title='Status: Open']"
    assert_includes response.body, "Open"
  end

  test "rendering component in a view with component: syntax" do
    get "/component"
    assert_response :success
    assert_html_matches <<~HTML, response.body
      <span><div>
        Foo
        bar
      </div>
      </span>
    HTML
  end

  test "rendering component with a partial" do
    get "/partial"
    assert_response :success
    assert_html_matches <<~HTML, response.body
      partial:<div>hello,partial world!</div>

      component:<div>hello,partial world!</div>

      <div>hello,partial world!</div>
    HTML
  end

  test "rendering component with deprecated syntax" do
    get "/deprecated"
    assert_response :success
    assert_html_matches <<~HTML, response.body
      <span><div>
        Foo
        bar
      </div>
      </span>
    HTML
  end

  test "rendering component without variant" do
    get "/variants"
    assert_response :success
    assert_html_matches "Default", response.body
  end

  test "rendering component with tablet variant" do
    get "/variants?variant=tablet"
    assert_response :success
    assert_html_matches "Tablet", response.body
  end

  test "rendering component several times with different variants" do
    get "/variants?variant=tablet"
    assert_response :success
    assert_html_matches "Tablet", response.body

    get "/variants?variant=phone"
    assert_response :success
    assert_html_matches "Phone", response.body

    get "/variants"
    assert_response :success
    assert_html_matches "Default", response.body

    get "/variants?variant=tablet"
    assert_response :success
    assert_html_matches "Tablet", response.body

    get "/variants?variant=phone"
    assert_response :success
    assert_html_matches "Phone", response.body
  end

  test "rendering component with caching" do
    Rails.cache.clear
    ActionController::Base.perform_caching = true

    get "/cached"
    assert_response :success
    assert_html_matches "Cached", response.body

    get "/cached"
    assert_response :success
    assert_html_matches "Cached", response.body

    ActionController::Base.perform_caching = false
    Rails.cache.clear
  end

  test "renders component preview" do
    get "/rails/components/my_component/default"

    assert_includes response.body, "<div>hello,world!</div>"
  end

  test "renders preview component default preview" do
    get "/rails/components/preview_component/default"

    assert_includes response.body, "Click me!"
  end

  test "renders preview component with_cta preview" do
    get "/rails/components/preview_component/without_cta"

    assert_includes response.body, "More lorem..."
  end

  test "renders preview component with content preview" do
    get "/rails/components/preview_component/with_content"

    assert_includes response.body, "some content"
  end

  test "renders badge component open preview" do
    get "/rails/components/issues/badge_component/open"

    assert_includes response.body, "Open"
  end

  test "renders badge component closed preview" do
    get "/rails/components/issues/badge_component/closed"

    assert_includes response.body, "Closed"
  end

  test "renders preview with args uses defaults" do
    get "/rails/components/erb_component/with_args"

    assert_includes response.body, "Hello World!"
    assert_includes response.body, "Bye!"
  end

  test "renders preview with args override" do
    get "/rails/components/erb_component/with_args", params: {message: "See ya later!"}

    assert_includes response.body, "Hello World!"
    assert_includes response.body, "See ya later!"
  end

  test "renders preview with content override" do
    get "/rails/components/erb_component/with_args", params: {message: "See ya later!", content: "Hey Buddy!"}

    assert_includes response.body, "Hey Buddy!"
    assert_includes response.body, "See ya later!"
  end

  test "renders preview with args extra params don't cause error" do
    get "/rails/components/erb_component/with_args", params: { message: "See ya later!", foo: "bar"}

    assert_includes response.body, "Hello World!"
    assert_includes response.body, "See ya later!"
  end

  test "renders preview without args with params don't cause error" do
    get "/rails/components/erb_component/default", params: { message: "See ya later!", foo: "bar"}

    assert_includes response.body, "Hello World!"
    assert_includes response.body, "Bye!"
  end

  test "compiles unreferenced component" do
    assert UnreferencedComponent.compiled?
  end
end
