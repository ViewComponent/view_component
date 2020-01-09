# frozen_string_literal: true

require "test_helper"

class ActionView::ComponentTest < ActionView::Component::TestCase
  def test_render_inline
    result = render_inline(MyComponent)

    assert_html_matches "<div>hello,world!</div>", result.to_html
    assert_html_matches "<div>hello,world!</div>", result.css("div").to_html
  end

  def test_render_inline_with_old_helper
    result = render_component(MyComponent)

    assert_html_matches "<div>hello,world!</div>", result.to_html
    assert_html_matches "<div>hello,world!</div>", result.css("div").to_html
  end

  def test_checks_validations
    exception = assert_raises ActiveModel::ValidationError do
      render_inline(WrapperComponent)
    end

    assert_includes exception.message, "Content can't be blank"
  end

  def test_renders_content_from_block
    result = render_inline(WrapperComponent) do
      "content"
    end

    assert_html_matches result.css("span").to_html, "<span>content</span>"
  end

  def test_renders_slim_template
    result = render_inline(SlimComponent, message: "bar") { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_haml_template
    result = render_inline(HamlComponent, message: "bar") { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_button_to_component
    old_value = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    result = render_inline(ButtonToComponent) { "foo" }

    assert_html_matches '<input type="submit" value="foo">', result.css("input[type=submit]").to_html
    assert result.css("form[class='button_to'][action='/'][method='post']").present?
    assert result.css("input[type='hidden'][name='authenticity_token']").present?

    ActionController::Base.allow_forgery_protection = old_value
  end

  def test_renders_component_with_variant
    with_variant :phone do
      result = render_inline(VariantsComponent)

      assert_includes result.text, "Phone"
    end
  end

  def test_renders_default_template_when_variant_template_is_not_present
    with_variant :variant_without_template do
      result = render_inline(VariantsComponent)

      assert_includes result.text, "Default"
    end
  end

  def test_renders_erb_template
    result = render_inline(ErbComponent, message: "bar") { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_erb_template_with_old_syntax
    result = render_inline(ErbComponent.new(message: "bar")) { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_erb_template_with_hash_syntax
    result = render_inline(component: ErbComponent, locals: { message: "bar" }) { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_partial_template
    result = render_inline(PartialComponent)

    assert_html_matches <<~HTML, result.to_html
      <div>hello,partial world!</div>

      <div>hello,partial world!</div>
    HTML
  end

  def test_renders_content_for_template
    result = render_inline(ContentForComponent)

    assert_html_matches "<div>Hello content for</div>", result.to_html
  end

  def test_renders_content_areas_template_with_initialize_arguments
    result = render_inline(ContentAreasComponent, title: "Hi!", footer: "Bye!") do |component|
      component.with(:body) { "Have a nice day." }
    end
  end

  def test_renders_content_areas_template_with_content
    result = render_inline(ContentAreasComponent, footer: "Bye!") do |component|
      component.with(:title, "Hello!")
      component.with(:body) { "Have a nice day." }
    end

    expected_html =
      %(<div>
          <div class="title">
            Hello!
          </div>
          <div class="body">
            Have a nice day.
          </div>
          <div class="footer">
            Bye!
          </div>
        </div>)

    assert_html_matches expected_html, result.to_html
  end

  def test_renders_content_areas_template_with_block
    result = render_inline(ContentAreasComponent, footer: "Bye!") do |component|
      component.with(:title) { "Hello!" }
      component.with(:body) { "Have a nice day." }
    end

    expected_html =
      %(<div>
          <div class="title">
            Hello!
          </div>
          <div class="body">
            Have a nice day.
          </div>
          <div class="footer">
            Bye!
          </div>
        </div>)

    assert_html_matches expected_html, result.to_html
  end

  def test_renders_content_areas_template_replaces_content
    result = render_inline(ContentAreasComponent, footer: "Bye!") do |component|
      component.with(:title) { "Hello!" }
      component.with(:title, "Hi!")
      component.with(:body) { "Have a nice day." }
    end

    expected_html =
      %(<div>
          <div class="title">
            Hi!
          </div>
          <div class="body">
            Have a nice day.
          </div>
          <div class="footer">
            Bye!
          </div>
        </div>)

    assert_html_matches expected_html, result.to_html
  end

  def test_renders_content_areas_template_can_wrap_render_arguments
    result = render_inline(ContentAreasComponent, title: "Hello!", footer: "Bye!") do |component|
      component.with(:title) { "<strong>#{component.title}</strong>".html_safe }
      component.with(:body) { "Have a nice day." }
    end

    expected_html =
      %(<div>
          <div class="title">
            <strong>Hello!</strong>
          </div>
          <div class="body">
            Have a nice day.
          </div>
          <div class="footer">
            Bye!
          </div>
        </div>)

    assert_html_matches expected_html, result.to_html
  end

  def test_renders_content_area_does_not_capture_block_content
    exception = assert_raises ActiveModel::ValidationError do
      render_inline(ContentAreasComponent, title: "Hi!", footer: "Bye!") { "Have a nice day." }
    end

    assert_includes exception.message, "Body can't be blank"
  end

  def test_renders_content_areas_template_raise_with_unknown_content_areas
    exception = assert_raises ArgumentError do
      render_inline(ContentAreasComponent, footer: "Bye!") do |component|
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
    result = render_inline(HelpersProxyComponent)

    assert_html_matches "<div>Hello helper method</div>", result.to_html
  end

  def test_renders_path_helper
    result = render_inline(PathComponent)

    assert_includes result.text, "/"
  end

  def test_renders_nested_path_helper
    result = render_inline(PathComponentContainer)

    assert_includes result.text, "/"
  end

  def test_renders_url_helper
    result = render_inline(UrlComponent)

    assert_includes result.text, "http://test.host/"
  end

  def test_renders_another_component
    result = render_inline(AnotherComponent)

    assert_html_matches "<div>hello,world!</div>", result.to_html
  end

  def test_renders_component_with_css_sidecar
    result = render_inline(CssSidecarFileComponent)

    assert_html_matches "<div>hello, world!</div>", result.to_html
  end

  def test_renders_component_with_request_context
    result = render_inline(RequestComponent)

    assert_html_matches "<div>0.0.0.0</div>", result.to_html
  end

  def test_renders_component_without_format
    result = render_inline(NoFormatComponent)

    assert_html_matches "<div>hello,world!</div>", result.to_html
  end

  def test_renders_component_with_asset_url
    result = render_inline(AssetComponent)

    assert_match %r{<div>http://assets.example.com/assets/application-\w+.css</div>}, trim_result(result.css("div").first.to_html)
  end

  def test_template_changes_are_not_reflected_in_production
    old_value = ActionView::Base.cache_template_loading
    ActionView::Base.cache_template_loading = true

    assert_html_matches "<div>hello,world!</div>", render_inline(MyComponent).to_html

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      assert_html_matches  "<div>hello,world!</div>", render_inline(MyComponent).to_html
    end

    assert_html_matches "<div>hello,world!</div>", render_inline(MyComponent).to_html

    ActionView::Base.cache_template_loading = old_value
  end

  def test_template_changes_are_reflected_outside_production
    old_value = ActionView::Base.cache_template_loading
    ActionView::Base.cache_template_loading = false

    assert_html_matches "<div>hello,world!</div>", render_inline(MyComponent).to_html

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      assert_html_matches "<div>Goodbye world!</div>", render_inline(MyComponent).to_html
    end

    assert_html_matches "<div>hello,world!</div>", render_inline(MyComponent).to_html

    ActionView::Base.cache_template_loading = old_value
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActionView::Component::VERSION::MAJOR
    assert_kind_of Integer, ::ActionView::Component::VERSION::MAJOR
    refute_nil ::ActionView::Component::VERSION::MINOR
    assert_kind_of Integer, ::ActionView::Component::VERSION::MINOR
    refute_nil ::ActionView::Component::VERSION::PATCH
    assert_kind_of Integer, ::ActionView::Component::VERSION::PATCH

    version_string = [
      ::ActionView::Component::VERSION::MAJOR,
      ::ActionView::Component::VERSION::MINOR,
      ::ActionView::Component::VERSION::PATCH
    ].join(".")
    assert_html_matches version_string, ::ActionView::Component::VERSION::STRING
  end

  def test_renders_component_with_translations
    assert_includes render_inline(TranslationsComponent).to_html,
                    "<h1>#{I18n.t('translations_component.title')}</h1>"

    assert_includes render_inline(TranslationsComponent).to_html,
                    "<h2>#{I18n.t('translations_component.subtitle')}</h2>"
  end

  def test_renders_component_with_rb_in_its_name
    assert_html_matches "Editorb!\n", render_inline(EditorbComponent).text
  end

  def test_conditional_rendering
    assert_includes render_inline(ConditionalRenderComponent, should_render: true).to_html,
                    "<div>component was rendered</div>"

    assert_equal render_inline(ConditionalRenderComponent, should_render: false).to_html,
                    ""

    exception = assert_raises ActiveModel::ValidationError do
      render_inline(ConditionalRenderComponent, should_render: nil)
    end
    assert_equal exception.message, "Validation failed: Should render is not included in the list"
  end

  def test_render_check
    assert_includes render_inline(RenderCheckComponent).text, "Rendered"
    controller.view_context.cookies[:shown] = true
    assert_empty render_inline(RenderCheckComponent).text, ""
  end

  def test_to_component_class
    post = Post.new(title: "Awesome post")

    assert_html_matches PostComponent, post.to_component_class
    assert_html_matches "<span>The Awesome post component!</span>", render_inline(post).to_html
  end

  def test_missing_initializer
    skip unless const_source_location_supported?

    assert_html_matches "Hello, world!", render_inline(MissingInitializerComponent).text
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
