# frozen_string_literal: true

require "test_helper"

class RenderPreviewTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.__vc_load_previews
  end

  def test_render_preview_from_class
    render_preview(:default, from: MyComponentPreview)

    assert_selector("div", text: "hello,world!")
  end

  def test_render_preview_with_url_helper
    render_preview(:default, from: UrlHelperComponentPreview)

    assert_selector("a[href='/']", text: "root")
  end

  def test_render_preview_replaces_the_page_from_an_inline_render
    render_inline(ErbComponent.new(message: "previous render"))
    assert_text "previous render"

    render_preview(:default, from: MyComponentPreview)

    assert_selector("div", text: "hello,world!")
    assert_no_text "previous render"
  end

  def test_render_preview_replaces_the_page_from_a_previous_preview
    render_preview(:with_content, from: MyComponentPreview, params: {content: "first preview"})
    assert_text "first preview"

    render_preview(:with_content, from: MyComponentPreview, params: {content: "second preview"})

    assert_text "second preview"
    assert_no_text "first preview"
  end

  def test_render_preview_unsuffixed
    render_preview(:other, from: Unsuffixed::OtherPreview)

    assert_selector("div", text: "subclass")
  end

  def test_render_preview_custom_path
    render_preview(:default, from: MyComponentLibPreview)

    assert_selector("div", text: "hello,world!")
  end
end
