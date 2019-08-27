# frozen_string_literal: true

require "test_helper"

class ActionView::ComponentTest < Minitest::Test
  include ActionView::ComponentTestHelpers

  def test_render_component
    result = render_component(MyComponent.new)

    assert_equal trim_result(result.css("div").first.to_html), "<div>hello,world!</div>"
  end

  def test_raises_error_when_sidecar_template_is_missing
    exception = assert_raises NotImplementedError do
      render_component(MissingTemplateComponent.new)
    end

    assert_includes exception.message, "Could not find a template file for MissingTemplateComponent"
  end

  def test_raises_error_when_more_then_one_sidecar_template_is_present
    error = assert_raises StandardError do
      render_component(TooManySidecarFilesComponent.new)
    end

    assert_includes error.message, "More than one template found for TooManySidecarFilesComponent."
  end

  def test_raises_error_when_initializer_is_not_defined
    exception = assert_raises NotImplementedError do
      render_component(MissingInitializerComponent.new)
    end

    assert_includes exception.message, "must implement #initialize"
  end

  def test_checks_validations
    exception = assert_raises ActiveModel::ValidationError do
      render_component(WrapperComponent.new)
    end

    assert_includes exception.message, "Content can't be blank"
  end

  def test_renders_content_from_block
    result = render_component(WrapperComponent.new) do
      "content"
    end

    assert_equal trim_result(result.css("span").first.to_html), "<span>content</span>"
  end

  def test_renders_slim_template
    result = render_component(SlimComponent.new(message: "bar")) { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_haml_template
    result = render_component(HamlComponent.new(message: "bar")) { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_erb_template
    result = render_component(ErbComponent.new(message: "bar")) { "foo" }

    assert_includes result.text, "foo"
    assert_includes result.text, "bar"
  end

  def test_renders_route_helper
    result = render_component(RouteComponent.new)

    assert_includes result.text, "/"
  end

  def test_template_changes_are_not_reflected_in_production
    ActionView::Base.cache_template_loading = true

    assert_equal "<div>hello,world!</div>", render_component(MyComponent.new).css("div").first.to_html

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      assert_equal  "<div>hello,world!</div>", render_component(MyComponent.new).css("div").first.to_html
    end

    assert_equal "<div>hello,world!</div>", render_component(MyComponent.new).css("div").first.to_html
  end

  def test_template_changes_are_reflected_outside_production
    ActionView::Base.cache_template_loading = false

    assert_equal "<div>hello,world!</div>", render_component(MyComponent.new).css("div").first.to_html

    modify_file "app/components/my_component.html.erb", "<div>Goodbye world!</div>" do
      assert_equal "<div>Goodbye world!</div>", render_component(MyComponent.new).css("div").first.to_html
    end

    assert_equal "<div>hello,world!</div>", render_component(MyComponent.new).css("div").first.to_html
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
