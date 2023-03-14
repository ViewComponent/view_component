require "test_helper"

class RequestFormatsTest < ActionDispatch::IntegrationTest
  def test_rendering_component_with_multiple_formats
    get "/request_formats"
    assert_response :success

    assert_select("p", "Hello, HTML World")
  end

  def test_rendering_text_format
    get "/request_formats.txt"
    assert_response :success

    assert_text("Hello, Text World")
  end
end
