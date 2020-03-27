# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActionDispatch::IntegrationTest
  test "rendering component in a view" do
    get "/"
    assert_response :success

    assert_select("div", "Foo\n  bar")
  end

  test "rendering component in a controller" do
    get "/controller_inline_baseline"

    assert_select("div", "bar")
    assert_response :success

    baseline_response = response.body

    get "/controller_inline"
    assert_select("div", "bar")
    assert_response :success

    inline_response = response.body

    assert_equal baseline_response, inline_response
  end

  test "rendering component with content" do
    get "/content"
    assert_response :success
    assert_select "div.State--green"
    assert_select "div[title='Status: Open']"
    assert_includes response.body, "Open"
  end

  test "rendering component with content_for" do
    get "/content_areas"
    assert_response :success

    assert_select(".title h1", "Hi!")
    assert_select(".body p", "Did you know that 1+1=2?")
    assert_select(".footer h3", "Bye!")
  end

  test "rendering component with a partial" do
    get "/partial"
    assert_response :success

    assert_includes response.body, "partial:<div>hello,partial world!"
    assert_includes response.body, "component:<div>hello,partial world!"
  end

  test "rendering component without variant" do
    get "/variants"
    assert_response :success
    assert_includes response.body, "Default"
  end

  test "rendering component with tablet variant" do
    get "/variants?variant=tablet"
    assert_response :success
    assert_includes response.body, "Tablet"
  end

  test "rendering component several times with different variants" do
    get "/variants?variant=tablet"
    assert_response :success
    assert_includes response.body, "Tablet"

    get "/variants?variant=phone"
    assert_response :success
    assert_includes response.body, "Phone"

    get "/variants"
    assert_response :success
    assert_includes response.body, "Default"

    get "/variants?variant=tablet"
    assert_response :success
    assert_includes response.body, "Tablet"

    get "/variants?variant=phone"
    assert_response :success
    assert_includes response.body, "Phone"
  end

  test "rendering component with caching" do
    Rails.cache.clear
    ActionController::Base.perform_caching = true

    get "/cached?version=1"
    assert_response :success
    assert_includes response.body, "Cache 1"

    get "/cached?version=2"
    assert_response :success
    assert_includes response.body, "Cache 1"

    ActionController::Base.perform_caching = false
    Rails.cache.clear
  end

  test "optional rendering component depending on request context" do
    get "/render_check"
    assert_response :success
    assert_includes response.body, "Rendered"

    cookies[:shown] = true

    get "/render_check"
    assert_response :success
    assert_empty response.body.strip
  end

  test "renders component preview" do
    get "/rails/view_components/my_component/default"

    assert_includes response.body, "<div>hello,world!</div>"
  end

  test "renders preview component default preview" do
    get "/rails/view_components/preview_component/default"

    assert_includes response.body, "Click me!"
  end

  test "renders preview component with_cta preview" do
    get "/rails/view_components/preview_component/without_cta"

    assert_includes response.body, "More lorem..."
  end

  test "renders preview component with content preview" do
    get "/rails/view_components/preview_component/with_content"

    assert_includes response.body, "some content"
  end

  test "renders preview component with tag helper-generated content preview" do
    get "/rails/view_components/preview_component/with_tag_helper_in_content"

    assert_includes response.body, "<span>some content</span>"
  end

  test "renders badge component open preview" do
    get "/rails/view_components/issues/badge_component/open"

    assert_includes response.body, "Open"
  end

  test "renders badge component closed preview" do
    get "/rails/view_components/issues/badge_component/closed"

    assert_includes response.body, "Closed"
  end

  test "test preview renders" do
    get "/rails/view_components/preview_component/default"

    assert_includes response.body, "ViewComponent - Test"
    assert_select(".preview-component .btn", "Click me!")
  end

  test "test preview renders with layout" do
    get "/rails/view_components/my_component/default"

    assert_includes response.body, "ViewComponent - Admin - Test"
    assert_select("div", "hello,world!")
  end

  test "test preview renders without layout" do
    get "/rails/view_components/no_layout/default"

    assert_select("div", "hello,world!")
  end

  test "renders collections" do
    get "/products"

    assert_select("h1", text: "Products for sale")
    assert_select("h1", text: "Product", count: 2)
    assert_select("h2", text: "Radio clock")
    assert_select("h2", text: "Mints")
    assert_select("p", text: "Today only", count: 2)
  end
end
