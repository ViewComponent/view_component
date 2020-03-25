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

  def test_render_without_template
    render_inline(InlineComponent.new)

    assert_predicate InlineComponent, :inlined?
    assert_not_predicate InlineComponent, :compiled?
    assert_selector("input[type='text'][name='name']")
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
    refute_component_rendered
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

  def test_compiles_unreferenced_component
    assert UnreferencedComponent.compiled?
  end

  def test_does_not_compile_components_without_initializers
    refute MissingInitializerComponent.compiled?
  end

  def test_raises_error_when_initializer_is_not_defined
    exception = assert_raises ViewComponent::TemplateError do
      render_inline(MissingInitializerComponent.new)
    end

    assert_includes exception.message, "must implement #initialize"
  end

  def test_raises_error_when_sidecar_template_is_missing
    exception = assert_raises ViewComponent::TemplateError do
      render_inline(MissingTemplateComponent.new)
    end

    assert_includes exception.message, "Could not find a template file for MissingTemplateComponent"
  end

  def test_raises_error_when_more_than_one_sidecar_template_is_present
    error = assert_raises ViewComponent::TemplateError do
      render_inline(TooManySidecarFilesComponent.new)
    end

    assert_includes error.message, "More than one template found for TooManySidecarFilesComponent."
  end

  def test_raises_error_when_more_than_one_sidecar_template_for_a_variant_is_present
    error = assert_raises ViewComponent::TemplateError do
      render_inline(TooManySidecarFilesForVariantComponent.new)
    end

    assert_includes error.message, "More than one template found for variants 'test' and 'testing' in TooManySidecarFilesForVariantComponent"
  end

  def test_backtrace_returns_correct_file_and_line_number
    error = assert_raises NameError do
      render_inline(ExceptionInTemplateComponent.new)
    end

    assert_match %r[app/components/exception_in_template_component\.html\.erb:2], error.backtrace[0]
  end

  # Some example usages:
  #
  # TODO: requires knowing the iterator name.
  # <%= render(ProductComponent.all(@products)) %>
  #
  # Done
  # <%= render(ProductComponent.all(collection: @products, as: :product, foo: foo)) %>
  # <%= render(ProductComponent.new(product: @product)) %>

  def test_render_collection
    @products = [OpenStruct.new(title: "Hi"), OpenStruct.new(title: "Bye")]
    render_inline(ProductComponent.all(collection: @products, extra: "extra"))

    assert_selector("h1", count: 2)
  end

  def test_render_collection_specify_as
    @products = [OpenStruct.new(title: "Hi"), OpenStruct.new(title: "Bye")]
    render_inline(ProductComponent.all(collection: @products, as: :product, extra: "extra"))

    assert_selector("h1", count: 2)
  end

  def test_render_collection_custom_as
    @coupons = [OpenStruct.new(title: "Hi"), OpenStruct.new(title: "Bye")]
    render_inline(ProductCouponComponent.all(collection: @coupons, as: :item))

    assert_selector("h3", count: 2)
  end

  def test_render_collection_invalid_as
    @products = [OpenStruct.new(title: "Hi"), OpenStruct.new(title: "Bye")]
    exception = assert_raises ArgumentError do
      render_inline(ProductComponent.all(collection: @products, as: "Product"))
    end

    assert_equal exception.message, "The value (Product) of the option `as` is not a valid Ruby identifier; make sure it starts with lowercase letter, and is followed by any combination of letters, numbers and underscores."
  end

  def test_render_collection_without_as
    @products = [OpenStruct.new(title: "Hi"), OpenStruct.new(title: "Bye")]
    render_inline(ProductItemComponent.all(collection: @products, extra: "extra"))

    assert_selector("h2", count: 2)
  end

  def test_render_single_item_from_collection
    @product = OpenStruct.new(title: "Bye")
    render_inline(ProductComponent.new(product: @product, extra: "abc"))

    assert_selector("h1", count: 1)
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
