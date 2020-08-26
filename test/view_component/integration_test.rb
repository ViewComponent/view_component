# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActionDispatch::IntegrationTest
  test "rendering component in a view" do
    get "/"
    assert_response :success

    assert_select("div", "Foo\n  bar")
  end

  if Rails.version.to_f >= 6.1
    test "rendering component with template annotations enabled" do
      get "/"
      assert_response :success

      assert_includes response.body, "BEGIN app/components/erb_component.rb"

      assert_select("div", "Foo\n  bar")
    end
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

    assert_includes inline_response, baseline_response
  end

  test "template changes are not reflected on new request when cache_template_loading is true" do
    # cache_template_loading is set to true on the initializer

    get "/controller_inline"
    assert_select("div", "bar")
    assert_response :success

    modify_file "app/components/controller_inline_component.html.erb", "<div>Goodbye world!</div>" do
      get "/controller_inline"
      assert_select("div", "bar")
      assert_response :success
    end

    get "/controller_inline"
    assert_select("div", "bar")
    assert_response :success
  end

  test "template changes are reflected on new request when cache_template_loading is false" do
    begin
      old_cache = ViewComponent::CompileCache.cache
      ViewComponent::CompileCache.cache = Set.new
      ActionView::Base.cache_template_loading = false

      get "/controller_inline"
      assert_select("div", "bar")
      assert_response :success

      modify_file "app/components/controller_inline_component.html.erb", "<div>Goodbye world!</div>" do
        get "/controller_inline"
        assert_select("div", "Goodbye world!")
        assert_response :success
      end

      get "/controller_inline"
      assert_select("div", "bar")
      assert_response :success
    ensure
      ActionView::Base.cache_template_loading = true
      ViewComponent::CompileCache.cache = old_cache
    end
  end

  test "rendering component in a controller using #render_to_string" do
    get "/controller_inline_baseline"

    assert_select("div", "bar")
    assert_response :success

    baseline_response = response.body

    get "/controller_to_string"
    assert_select("div", "bar")
    assert_response :success

    to_string_response = response.body

    assert_includes to_string_response, baseline_response
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

    assert_select("div", "hello,partial world!", count: 2)
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
    refute_includes response.body, "Rendered"
  end

  test "renders component preview" do
    get "/rails/view_components/my_component/default"

    assert_includes response.body, "<div>hello,world!</div>"
  end

  test "renders preview component default preview" do
    get "/rails/view_components/preview_component/default"

    assert_includes response.body, "Click me!"
  end

  test "renders preview component default preview ignoring params" do
    get "/rails/view_components/preview_component/default?cta=CTA+from+params"

    assert_includes response.body, "Click me!"

    refute_includes response.body, "CTA from params"
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

  test "renders preview component with params preview with default values" do
    get "/rails/view_components/preview_component/with_params"

    assert_includes response.body, "Default CTA"
    assert_includes response.body, "Default title"
  end

  test "renders preview component with params preview with one param" do
    get "/rails/view_components/preview_component/with_params?cta=CTA+from+params"

    assert_includes response.body, "CTA from params"
    assert_includes response.body, "Default title"
  end

  test "renders preview component with params preview with multiple params" do
    get "/rails/view_components/preview_component/with_params?cta=CTA+from+params&title=Title+from+params"

    assert_includes response.body, "CTA from params"
    assert_includes response.body, "Title from params"
  end

  test "renders preview component with params preview ignoring unsupported params" do
    get "/rails/view_components/preview_component/with_params?cta=CTA+from+params&label=Label+from+params"

    assert_includes response.body, "CTA from params"
    assert_includes response.body, "Default title"

    refute_includes response.body, "Label from params"
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
    refute_includes response.body, "ViewComponent - Test"
  end

  test "test preview renders application's layout by default" do
    get "/rails/view_components/preview_component/default"

    assert_select "title", "ViewComponent - Test"
  end

  test "test preview index renders rails application layout by default" do
    get "/rails/view_components"

    assert_select "title", "Component Previews"
  end

  test "test preview index of a component renders rails application layout by default" do
    get "/rails/view_components/preview_component"

    assert_select "title", "Component Previews for preview_component"
  end

  test "test preview related views are being rendered correctly" do
    get "/rails/view_components"
    assert_select "title", "Component Previews"

    get "/rails/view_components/preview_component/default"
    assert_select "title", "ViewComponent - Test"

    get "/rails/view_components/preview_component"
    assert_select "title", "Component Previews for preview_component"
  end

  test "test preview from multiple preview_paths" do
    get "/rails/view_components/my_component_lib/default"
    assert_select("div", "hello,world!")
  end

  test "renders collections" do
    get "/products"

    assert_select("h1", text: "Products for sale")
    assert_select("h1", text: "Product", count: 2)
    assert_select("h2", text: "Radio clock")
    assert_select("h2", text: "Mints")
    assert_select("p", text: "Today only", count: 2)
    assert_select("p", text: "Radio clock counter: 1")
    assert_select("p", text: "Mints counter: 2")
  end

  test "renders the previews in the configured route" do
    with_preview_route("/previews") do
      get "/previews"
      assert_select "title", "Component Previews"

      get "/previews/preview_component/default"
      assert_select "title", "ViewComponent - Test"

      get "/previews/preview_component"
      assert_select "title", "Component Previews for preview_component"
    end
  end

  test "renders singular and collection slots with arguments" do
    get "/slots"

    assert_select(".card.mt-4")

    assert_select(".title p", text: "This is my title!")

    assert_select(".subtitle small", text: "This is my subtitle!")

    assert_select(".tab", text: "Tab A")
    assert_select(".tab", text: "Tab B")

    assert_select(".item", count: 3)
    assert_select(".item.highlighted", count: 1)
    assert_select(".item.normal", count: 2)

    assert_select(".footer.text-blue h3", text: "This is the footer")

    title_node = Nokogiri::HTML.fragment(response.body).css(".title").to_html
    expected_title_html = "<div class=\"title\">\n    <p>This is my title!</p>\n  </div>"

    assert_equal(title_node, expected_title_html)
  end

  test "renders empty slot without error" do
    get "/empty_slot"

    assert_response :success
  end

  if Rails.version.to_f >= 6.1
    test "rendering component using the render_component helper raises an error" do
      error = assert_raises ActionView::Template::Error do
        get "/render_component"
      end
      assert_match /undefined method `render_component'/, error.message
    end
  end

  if Rails.version.to_f < 6.1
    test "rendering component using #render_component" do
      get "/render_component"
      assert_includes response.body, "bar"
    end

    test "rendering component in a controller using #render_component" do
      get "/controller_inline_render_component"
      assert_includes response.body, "bar"
    end

    test "rendering component in a controller using #render_component_to_string" do
      get "/controller_to_string_render_component"
      assert_includes response.body, "bar"
    end

    test "rendering component in preview using #render_component and monkey patch disabled" do
      with_render_monkey_patch_config(false) do
        get "/rails/view_components/monkey_patch_disabled_component/default"
        assert_includes response.body, "<div>hello,world!</div>"
      end
    end
  end

  test "renders the inline component preview examples with default behaviour and with their own templates" do
    get "/rails/view_components/inline_component/default"
    assert_select "input" do
      assert_select "[name=?]", "name"
    end

    get "/rails/view_components/inline_component/inside_form"
    assert_select "form" do
      assert_select "p", "Inside Form"
      assert_select "input[name=?]", "name"
    end

    get "/rails/view_components/inline_component/outside_form"
    assert_select "div" do
      assert_select "p", "Outside Form"
      assert_select "input[name=?]", "name"
    end
  end

  test "renders the preview example with its own template and a layout" do
    get "/rails/view_components/my_component/inside_banner"
    assert_includes response.body, "ViewComponent - Admin - Test"
    assert_select ".banner" do
      assert_select("div", "hello,world!")
    end
  end

  test "renders an inline component preview using URL params and a template" do
    get "/rails/view_components/inline_component/with_params?form_title=This is a test form"
    assert_select "form" do
      assert_select "p", "This is a test form"
      assert_select "input[name=?]", "name"
    end
  end

  test "renders the inline component using a non standard-located template" do
    get "/rails/view_components/inline_component/with_non_standard_template"
    assert_select "h1", "This is not a standard place to have a preview template"
    assert_select "input[name=?]", "name"
  end

  test "renders an inline component preview using a HAML template" do
    get "/rails/view_components/inline_component/with_haml"
    assert_select "h1", "Some HAML here"
    assert_select "input[name=?]", "name"
  end

  test "returns 404 when preview does not exist" do
    assert_raises AbstractController::ActionNotFound do
      get "/rails/view_components/missing_preview"
    end
  end

  test "raises an error if the template is not present and the render_with_template method is used in the example" do
    error = assert_raises ViewComponent::PreviewTemplateError do
      get "/rails/view_components/inline_component/without_template"
    end
    assert_match /preview template for example without_template does not exist/, error.message
  end

  test "renders a preview template using HAML, params from URL, custom template and locals" do
    get "/rails/view_components/inline_component/with_several_options?form_title=Title from params"

    assert_select "form" do
      assert_select "h1", "Title from params"
      assert_select "input[name=?]", "name"
      assert_select "input[value=?]", "Send this form!"
    end
  end
end
