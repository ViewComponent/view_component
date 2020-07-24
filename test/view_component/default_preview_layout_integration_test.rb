# frozen_string_literal: true

require "test_helper"

class DefaultPreviewLayoutIntegrationTest < ActionDispatch::IntegrationTest
  test "preview index renders custom application layout if configured" do
    with_default_preview_layout("admin") do
      get "/rails/view_components"
      assert_select "title", "ViewComponent - Admin - Test"
    end
  end

  test "preview index of a component renders custom application layout if configured" do
    with_default_preview_layout("admin") do
      get "/rails/view_components/preview_component"
      assert_select "title", "ViewComponent - Admin - Test"
    end
  end

  test "component preview renders custom application layout if configured" do
    with_default_preview_layout("admin") do
      get "/rails/view_components/preview_component/default"
      assert_select "title", "ViewComponent - Admin - Test"
      assert_select ".preview-component .btn", "Click me!"
    end
  end

  test "component preview renders standard Rails layout if configured false" do
    with_default_preview_layout(false) do
      get "/rails/view_components/preview_component/default"

      assert_select "title", "ViewComponent - Test"
      assert_select ".preview-component .btn", "Click me!"
    end
  end

  test "preview renders without layout even if default layout is configured" do
    with_default_preview_layout("admin") do
      get "/rails/view_components/no_layout/default"
      assert_select("div", "hello,world!")
      refute_includes response.body, "ViewComponent - Admin - Test"
    end
  end
end
