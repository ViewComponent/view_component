# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActionDispatch::IntegrationTest
  test "rendering component in a view" do
    get "/"
    assert_response :success
    assert_equal trim_result(response.body), "<span><div>Foobar</div></span>"
  end

  test "rendering component in a view with component: syntax" do
    get "/component"
    assert_response :success
    assert_equal trim_result(response.body), "<span><div>Foobar</div></span>"
  end

  test "rendering component with a partial" do
    if Rails::VERSION::MAJOR >= 6
      assert_raises ActionView::Template::Error do
        get "/partial_component"
      end
    else
      get "/partial_component"
      assert_response :success
      assert_equal trim_result(response.body), "partial:<div>hello,partialworld!</div>component:<div>hello,partialworld!</div>"
    end
  end

  test "rendering component in a view with deprecated syntax" do
    get "/deprecated"
    assert_response :success
    assert_equal trim_result(response.body), "<span><div>Foobar</div></span>"
  end
end
