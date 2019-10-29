# frozen_string_literal: true

require "test_helper"

class ActionView::ComponentTest < Minitest::Test
  include ActionView::Component::TestHelpers

  def test_render_inline
    result = render_inline(MyComponent)

    assert_equal trim_result(result.first.to_html), "<div>hello,world!</div>"
    assert_equal trim_result(result.css("div").first.to_html), "<div>hello,world!</div>"
  end

  def test_render_inline_with_old_helper
    result = render_component(MyComponent)

    assert_equal trim_result(result.first.to_html), "<div>hello,world!</div>"
    assert_equal trim_result(result.css("div").first.to_html), "<div>hello,world!</div>"
  end

  def test_raises_error_when_sidecar_template_is_missing
    exception = assert_raises NotImplementedError do
      render_inline(MissingTemplateComponent)
    end

    assert_includes exception.message, "Could not find a template file for MissingTemplateComponent"
  end

  def test_raises_error_when_more_then_one_sidecar_template_is_present
    error = assert_raises StandardError do
      render_inline(TooManySidecarFilesComponent)
    end

    assert_includes error.message, "More than one template found for TooManySidecarFilesComponent."
  end

  def test_raises_error_when_initializer_is_not_defined
    exception = assert_raises NotImplementedError do
      render_inline(MissingInitializerComponent)
    end

    assert_includes exception.message, "must implement #initialize"
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

    assert_equal trim_result(result.css("span").first.to_html), "<span>content</span>"
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
    result = render_inline(ButtonToComponent) { "foo" }

    assert_equal '<input type="submit" value="foo">', result.css("input[type=submit]").to_html
    assert result.css("form[class='button_to'][action='/'][method='post']").present?
    assert result.css("input[type='hidden'][name='authenticity_token']").present?
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

    assert_equal "<div>hello,partial world!</div>", result.first.to_html
  end

  def test_renders_content_for_template
    result = render_inline(ContentForComponent)

    assert_equal "<div>Hello content for</div>", result.first.to_html
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

    assert_equal trim_result(result.first.to_html), "<div>hello,world!</div>"
  end

  def test_renders_component_with_css_sidecar
    result = render_inline(CssSidecarFileComponent)

    assert_equal trim_result(result.first.to_html), "<div>hello,world!</div>"
  end

  def test_renders_component_with_request_context
    result = render_inline(RequestComponent)

    assert_equal trim_result(result.first.to_html), "<div>0.0.0.0</div>"
  end

  def test_renders_component_without_format
    result = render_inline(NoFormatComponent)

    assert_equal trim_result(result.first.to_html), "<div>hello,world!</div>"
  end

  def test_template_changes_are_not_reflected_in_production
    old_value = ActionView::Base.cache_template_loading
    ActionView::Base.cache_template_loading = true

    assert_equal "<div>hello,world!</div>", render_inline(MyComponent).first.to_html

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      assert_equal  "<div>hello,world!</div>", render_inline(MyComponent).first.to_html
    end

    assert_equal "<div>hello,world!</div>", render_inline(MyComponent).first.to_html

    ActionView::Base.cache_template_loading = old_value
  end

  def test_template_changes_are_reflected_outside_production
    old_value = ActionView::Base.cache_template_loading
    ActionView::Base.cache_template_loading = false

    assert_equal "<div>hello,world!</div>", render_inline(MyComponent).first.to_html

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      assert_equal "<div>Goodbye world!</div>", render_inline(MyComponent).first.to_html
    end

    assert_equal "<div>hello,world!</div>", render_inline(MyComponent).first.to_html

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
    assert_equal version_string, ::ActionView::Component::VERSION::STRING
  end

  def test_renders_component_with_translations
    assert_includes render_inline(TranslationsComponent).first.to_html,
                    "<h1>#{I18n.t('components.translations_component.title')}</h1>"

    assert_includes render_inline(TranslationsComponent).first.to_html,
                    "<h2>#{I18n.t('components.translations_component.subtitle')}</h2>"
  end

  def test_renders_component_with_rb_in_its_name
    assert_equal "Editorb!\n", render_inline(EditorbComponent).text
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
