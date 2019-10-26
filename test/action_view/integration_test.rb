# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActionDispatch::IntegrationTest
  test "rendering component in a view" do
    get "/"
    assert_response :success
    assert_equal trim_result(response.body), "<span><div>Foobar</div></span>"
  end

  test "rendering component with content" do
    get "/content"
    assert_response :success
    assert_select "div.State--green"
    assert_select "div[title='Status: Open']"
    assert_includes response.body, "Open"
  end

  test "rendering component in a view with component: syntax" do
    get "/component"
    assert_response :success
    assert_equal trim_result(response.body), "<span><div>Foobar</div></span>"
  end

  test "rendering component with a partial" do
    get "/partial"
    assert_response :success
    assert_equal trim_result(response.body), "partial:<div>hello,partialworld!</div>component:<div>hello,partialworld!</div><div>hello,partialworld!</div>"
  end

  test "rendering component in a view with deprecated syntax" do
    get "/deprecated"
    assert_response :success
    assert_equal trim_result(response.body), "<span><div>Foobar</div></span>"
  end

  test "rendering component without variant" do
    get "/variants"
    assert_response :success
    assert_equal "<span>Default</span>", trim_result(response.body)
  end

  test "rendering component with tablet variant" do
    get "/variants?tablet=true"
    assert_response :success
    assert_equal "<span>Tablet</span>", trim_result(response.body)
  end

  test "rendering component several times with different variants" do
    get "/variants?tablet=true"
    assert_response :success
    assert_equal "<span>Tablet</span>", trim_result(response.body)

    get "/variants?phone=true"
    assert_response :success
    assert_equal "<span>Phone</span>", trim_result(response.body)

    get "/variants"
    assert_response :success
    assert_equal "<span>Default</span>", trim_result(response.body)

    get "/variants?tablet=true"
    assert_response :success
    assert_equal "<span>Tablet</span>", trim_result(response.body)

    get "/variants?phone=true"
    assert_response :success
    assert_equal "<span>Phone</span>", trim_result(response.body)
  end
end
