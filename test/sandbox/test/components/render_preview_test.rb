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

  def test_render_preview_does_not_retain_previous_parameters
    render_preview(:with_params, from: PreviewComponentPreview, params: {title: "First preview"})
    assert_text "First preview"

    render_preview(:with_params, from: PreviewComponentPreview)

    assert_text "Default title"
    assert_no_text "First preview"
  end

  def test_render_preview_preserves_the_original_request_parameters
    with_request_url("/products?retained=original") do
      request = vc_test_request
      original_parameters = request.params.deep_dup

      render_preview(:with_params, from: PreviewComponentPreview, params: {title: "Preview title"})

      assert_text "Preview title"
      assert_same request, vc_test_request
      assert_equal original_parameters, vc_test_request.params
      assert_equal "retained=original", vc_test_request.query_string
    end
  end

  def test_render_preview_runs_locale_callbacks_and_restores_the_locale
    render_args = PreviewComponentPreview.method(:render_args)
    locales = []
    capture_locale = lambda do |name, **options|
      locales << I18n.locale
      render_args.call(name, **options)
    end

    I18n.with_locale(:en) do
      PreviewComponentPreview.stub(:render_args, capture_locale) do
        render_preview(:default, from: PreviewComponentPreview, params: {locale: "fr"})
      end

      assert_equal [:fr], locales
      assert_equal :en, I18n.locale
    end
  end

  def test_render_preview_restores_locale_and_parameters_after_an_error
    original_parameters = vc_test_request.params.deep_dup
    I18n.with_locale(:en) do
      PreviewComponentPreview.stub(:render_args, ->(*) { raise "preview failure" }) do
        assert_raises(RuntimeError) do
          render_preview(:default, from: PreviewComponentPreview, params: {locale: "fr", title: "Preview title"})
        end
      end

      assert_equal :en, I18n.locale
      assert_equal original_parameters, vc_test_request.params
    end
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
