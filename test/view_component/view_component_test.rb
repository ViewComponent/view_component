# frozen_string_literal: true

require "test_helper"

class ViewComponentTest < ViewComponent::TestCase
  def test_render_inline
    render_inline(MyComponent.new)

    assert_selector("div", text: "hello,world!")
  end

  def test_renders_content_from_block
    render_inline(WrapperComponent.new) do
      "content"
    end

    assert_selector("span", text: "content")
  end

  def test_renders_slim_template
    render_inline(SlimComponent.new(message: "bar")) { "foo" }

    assert_text("foo")
    assert_text("bar")
  end

  def test_renders_haml_template
    render_inline(HamlComponent.new(message: "bar")) { "foo" }

    assert_text("foo")
    assert_text("bar")
  end

  def test_renders_button_to_component
    old_value = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    render_inline(ButtonToComponent.new) { "foo" }

    assert_selector("form[class='button_to'][action='/'][method='post']")
    assert_selector("input[type='hidden'][name='authenticity_token']", visible: false)

    ActionController::Base.allow_forgery_protection = old_value
  end

  def test_renders_component_with_variant
    with_variant :phone do
      render_inline(VariantsComponent.new)

      assert_text("Phone")
    end
  end

  def test_renders_default_template_when_variant_template_is_not_present
    with_variant :variant_without_template do
      render_inline(VariantsComponent.new)

      assert_text("Default")
    end
  end

  def test_template_with_old_class_syntax_fails
    assert_raises ArgumentError do
      render_inline(ErbComponent, message: "bar") { "foo" }
    end
  end

  def test_hash_render_syntax_fails
    assert_raises ArgumentError do
      render_inline(component: ErbComponent, locals: { message: "bar" }) { "foo" }
    end
  end

  def test_renders_erb_template
    render_inline(ErbComponent.new(message: "bar")) { "foo" }

    assert_text("foo")
    assert_text("bar")
  end

  def test_renders_partial_template
    render_inline(PartialComponent.new)

    assert_text("hello,partial world!\n\nhello,partial world!")
  end

  def test_renders_content_for_template
    render_inline(ContentForComponent.new)

    assert_text("Hello content for")
  end

  def test_renders_content_areas_template_with_initialize_arguments
    render_inline(ContentAreasComponent.new(title: "Hi!", footer: "Bye!")) do |component|
      component.with(:body) { "Have a nice day." }
    end
  end

  def test_renders_content_areas_template_with_content
    render_inline(ContentAreasComponent.new(footer: "Bye!")) do |component|
      component.with(:title, "Hello!")
      component.with(:body) { "Have a nice day." }
    end

    assert_selector(".title", text: "Hello!")
    assert_selector(".body", text: "Have a nice day.")
    assert_selector(".footer", text: "Bye!")
  end

  def test_renders_content_areas_template_with_block
    render_inline(ContentAreasComponent.new(footer: "Bye!")) do |component|
      component.with(:title) { "Hello!" }
      component.with(:body) { "Have a nice day." }
    end

    assert_selector(".title", text: "Hello!")
    assert_selector(".body", text: "Have a nice day.")
    assert_selector(".footer", text: "Bye!")
  end

  def test_renders_content_areas_template_replaces_content
    render_inline(ContentAreasComponent.new(footer: "Bye!")) do |component|
      component.with(:title) { "Hello!" }
      component.with(:title, "Hi!")
      component.with(:body) { "Have a nice day." }
    end

    assert_selector(".title", text: "Hi!")
    assert_selector(".body", text: "Have a nice day.")
    assert_selector(".footer", text: "Bye!")
  end

  def test_renders_content_areas_template_can_wrap_render_arguments
    render_inline(ContentAreasComponent.new(title: "Hello!", footer: "Bye!")) do |component|
      component.with(:title) { "<strong>#{component.title}</strong>".html_safe }
      component.with(:body) { "Have a nice day." }
    end

    assert_selector(".title strong", text: "Hello!")
    assert_selector(".body", text: "Have a nice day.")
    assert_selector(".footer", text: "Bye!")
  end

  def test_renders_content_areas_template_raise_with_unknown_content_areas
    exception = assert_raises ArgumentError do
      render_inline(ContentAreasComponent.new(footer: "Bye!")) do |component|
        component.with(:foo) { "Hello!" }
      end
    end

    assert_includes exception.message, "Unknown content_area 'foo' - expected one of '[:title, :body, :footer]'"
  end

  def test_with_content_areas_raise_with_content_keyword
    exception = assert_raises ArgumentError do
      ContentAreasComponent.with_content_areas :content
    end

    assert_includes exception.message, ":content is a reserved content area name"
  end

  def test_renders_helper_method_through_proxy
    render_inline(HelpersProxyComponent.new)

    assert_text("Hello helper method")
  end

  def test_renders_path_helper
    render_inline(PathComponent.new)

    assert_text("/")
  end

  def test_renders_nested_path_helper
    render_inline(PathContainerComponent.new)

    assert_text("/")
  end

  def test_renders_url_helper
    render_inline(UrlComponent.new)

    assert_text("http://test.host/")
  end

  def test_renders_another_component
    render_inline(AnotherComponent.new)

    assert_text("hello,world!")
  end

  def test_renders_component_with_css_sidecar
    render_inline(CssSidecarFileComponent.new)

    assert_text("hello, world!")
  end

  def test_renders_component_with_request_context
    render_inline(RequestComponent.new)

    assert_text("0.0.0.0")
  end

  def test_renders_component_without_format
    render_inline(NoFormatComponent.new)

    assert_text("hello,world!")
  end

  def test_renders_component_with_asset_url
    render_inline(AssetComponent.new)

    assert_text(%r{http://assets.example.com/assets/application-\w+.css})
  end

  def test_template_changes_are_not_reflected_in_production
    old_value = ActionView::Base.cache_template_loading
    ActionView::Base.cache_template_loading = true

    render_inline(MyComponent.new)

    assert_text("hello,world!")

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      render_inline(MyComponent.new)

      assert_no_text("Goodbye world!")
    end

    render_inline(MyComponent.new)

    ActionView::Base.cache_template_loading = old_value
  end

  def test_template_changes_are_reflected_outside_production
    old_value = ActionView::Base.cache_template_loading
    ActionView::Base.cache_template_loading = false

    render_inline(MyComponent.new)

    assert_text("hello,world!")

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      render_inline(MyComponent.new)

      assert_text("Goodbye world!")
    end

    render_inline(MyComponent.new)

    assert_text("hello,world!")

    ActionView::Base.cache_template_loading = old_value
  end

  def test_that_it_has_a_version_number
    refute_nil ::ViewComponent::VERSION::MAJOR
    assert_kind_of Integer, ::ViewComponent::VERSION::MAJOR
    refute_nil ::ViewComponent::VERSION::MINOR
    assert_kind_of Integer, ::ViewComponent::VERSION::MINOR
    refute_nil ::ViewComponent::VERSION::PATCH
    assert_kind_of Integer, ::ViewComponent::VERSION::PATCH

    version_string = [
      ::ViewComponent::VERSION::MAJOR,
      ::ViewComponent::VERSION::MINOR,
      ::ViewComponent::VERSION::PATCH
    ].join(".")
    assert_equal version_string, ::ViewComponent::VERSION::STRING
  end

  def test_renders_component_with_translations
    render_inline(TranslationsComponent.new)

    assert_selector("h1", text: I18n.t("translations_component.title"))
    assert_selector("h2", text: I18n.t("translations_component.subtitle"))
  end

  def test_renders_component_with_rb_in_its_name
    render_inline(EditorbComponent.new)

    assert_text("Editorb")
  end

  def test_conditional_rendering
    render_inline(ConditionalRenderComponent.new(should_render: true))

    assert_text("component was rendered")

    render_inline(ConditionalRenderComponent.new(should_render: false))

    assert_no_text("component was rendered")

    exception = assert_raises RuntimeError do
      render_inline(ConditionalRenderComponent.new(should_render: nil))
    end
    assert_equal exception.message, "should_render wasn't validated!"
  end

  def test_render_check
    render_inline(RenderCheckComponent.new)

    assert_text("Rendered")

    controller.view_context.cookies[:shown] = true

    render_inline(RenderCheckComponent.new)

    assert_no_text("Rendered")
  end

  def test_assert_select
    render_inline(MyComponent.new)

    assert_selector("div")
  end

  def test_no_validations_component
    render_inline(NoValidationsComponent.new)

    assert_selector("div")
  end

  def test_validations_component
    exception = assert_raises ActiveModel::ValidationError do
      render_inline(ValidationsComponent.new)
    end

    assert_equal exception.message, "Validation failed: Content can't be blank"
  end

  private

  def modify_file(file, content)
    filename = Rails.root.join(file)
    old_content = File.read(filename)
    begin
      File.open(filename, "wb+") { |f| f.write(content) }
      yield
    ensure
      File.open(filename, "wb+") { |f| f.write(old_content) }
    end
  end
end
