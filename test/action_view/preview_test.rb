# frozen_string_literal: true

require "test_helper"

class ActionView::PreviewTest < ActionView::Component::TestCase
  def test_preview
    assert_html_document(
      PreviewComponentPreview.call(:default),
      "Action View Component - Test",
      <<~HTML
        <div class="preview-component">
        <h1>Lorem Ipsum</h1>

        <button class="btn">Click me!</button>

        </div>
      HTML
    )
  end

  def test_preview_with_layout
    assert_html_document(
      MyComponentPreview.call(:default),
      "Action View Component - Admin - Test",
      "<div>hello,world!</div>"
    )
  end

  def test_preview_layout_override_with_false
    assert_html_fragment(
      MyComponentPreview.call(:default, layout: false),
      "<div>hello,world!</div>"
    )
  end

  def test_preview_with_no_layout
    assert_html_fragment(
      NoLayoutPreview.call(:default),
      "<div>hello,world!</div>"
    )
  end

  def test_preview_with_no_layout_override
    assert_html_document(
      NoLayoutPreview.call(:default, layout: "application"),
      "Action View Component - Test",
      "<div>hello,world!</div>"
    )
  end

  private

  def assert_html_document(preview_result, expected_title, expected_body)
    result = Nokogiri::HTML(preview_result)
    assert_html_matches expected_title, result.css('title').inner_html
    assert_html_matches expected_body, result.css('body').inner_html
  end

  def assert_html_fragment(preview_result, expected_fragment)
    result = Nokogiri::HTML.fragment(preview_result)
    assert_html_matches expected_fragment, result.to_html
  end

end
