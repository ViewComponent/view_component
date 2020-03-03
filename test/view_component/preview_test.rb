# frozen_string_literal: true

require "test_helper"

class ViewComponent::PreviewTest < ActionDispatch::IntegrationTest
  def test_preview
    get "/rails/components/preview_component/default"

    assert_html_document(
      response.body,
      "ViewComponent - Test",
      <<~HTML
        <div class="preview-component">
        <h1>Lorem Ipsum</h1>

        <button class="btn">Click me!</button>

        </div>
      HTML
    )
  end

  def test_preview_with_layout
    get "/rails/components/my_component/default"

    assert_html_document(
      response.body,
      "ViewComponent - Admin - Test",
      "<div>hello,world!</div>"
    )
  end

  def test_preview_with_no_layout
    get "/rails/components/no_layout/default"

    assert_html_fragment(
      response.body,
      "<div>hello,world!</div>"
    )
  end

  private

  def assert_html_document(preview_result, expected_title, expected_body)
    result = Nokogiri::HTML(preview_result)
    assert_html_matches expected_title, result.css("title").inner_html
    assert_html_matches expected_body, result.css("body").inner_html
  end

  def assert_html_fragment(preview_result, expected_fragment)
    result = Nokogiri::HTML.fragment(preview_result)
    assert_html_matches expected_fragment, result.to_html
  end

  def assert_html_matches(expected, actual)
    assert_equal(trim_result(expected), trim_result(actual))
  end
end
