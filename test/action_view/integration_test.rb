# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActionDispatch::IntegrationTest
  test "rendering component in a view" do
    get "/"
    assert_response :success
    assert_equal trim_result(response.body), "<span><div>Foobar</div></span>"
  end
end
