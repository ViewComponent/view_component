# frozen_string_literal: true

require "test_helper"

class RequestUrlComponentTest < ViewComponent::TestCase
  test "should print path and fullpath" do
    with_request_url "/products" do
      render_inline(RequestUrlComponent.new)

      assert_selector ".path", text: "/products"
      assert_selector ".fullpath", text: "/products"
    end

    with_request_url "/slots?param=1&paramtwo=2" do
      render_inline(RequestUrlComponent.new)

      assert_selector ".path", text: "/slots"
      assert_selector ".fullpath", text: "/slots?param=1&paramtwo=2"
    end

    with_request_url "/slots" do
      render_inline(RequestUrlComponent.new)

      assert_selector ".path", text: "/slots"
      assert_selector ".fullpath", text: "/slots"
    end
  end
end
