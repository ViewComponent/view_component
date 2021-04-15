# frozen_string_literal: true

require "test_helper"

class DefaultPreviewLayoutIntegrationTest < ActionDispatch::IntegrationTest
  def test_preview_index_renders_custom_application_layout_if_configured
    with_default_preview_layout("admin") do
      get "/rails/view_components"
      assert_select "title", "ViewComponent - Admin - Test"
    end
  end

  def test_preview_index_of_a_component_renders_custom_application_layout_if_configured
    with_default_preview_layout("admin") do
      get "/rails/view_components/preview_component"
      assert_select "title", "ViewComponent - Admin - Test"
    end
  end

  def test_component_preview_renders_custom_application_layout_if_configured
    with_default_preview_layout("admin") do
      get "/rails/view_components/preview_component/default"
      assert_select "title", "ViewComponent - Admin - Test"
      assert_select ".preview-component .btn", "Click me!"
    end
  end

  def test_component_preview_renders_standard_rails_layout_if_configured_false
    with_default_preview_layout(false) do
      get "/rails/view_components/preview_component/default"

      assert_select "title", "ViewComponent - Test"
      assert_select ".preview-component .btn", "Click me!"
    end
  end

  def test_preview_renders_without_layout_even_if_default_layout_is_configured
    with_default_preview_layout("admin") do
      get "/rails/view_components/no_layout/default"
      assert_select("div", "hello,world!")
      refute_includes response.body, "ViewComponent - Admin - Test"
    end
  end

  def test_component_preview_renders_source_preview
    get "/rails/view_components/preview_component/default"

    assert_select ".view-component-source-example h2", "Source:"
    assert_select ".view-component-source-example pre.source code"
  end

  def test_component_preview_renders_source_preview_if_layout_configured_false
    with_default_preview_layout(false) do
      get "/rails/view_components/preview_component/default"

      assert_select ".view-component-source-example h2", "Source:"
      assert_select ".view-component-source-example pre.source code"
    end
  end

  def test_component_preview_renders_source_preview_if_default_layout_is_configured
    with_default_preview_layout("preview") do
      get "/rails/view_components/no_layout/default"

      refute_includes response.body, "ViewComponent - Preview - Test"
      assert_select ".view-component-source-example h2", "Source:"
      assert_select ".view-component-source-example pre.source code"
    end
  end
end
