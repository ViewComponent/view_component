# frozen_string_literal: true

require "test_helper"

class TestHelperTest < ViewComponent::TestCase
  def test_with_request_url_inside_slots_path
    with_request_url "/slots" do
      render_inline(CurrentPageComponent.new)
    end

    assert_selector("div", text: "Inside /slots")
  end

  def test_with_request_url_outside_slots_path
    with_request_url "/" do
      render_inline(CurrentPageComponent.new)
    end

    assert_selector("div", text: "Outside /slots")
  end

  def test_with_request_url_under_constraint
    warden = Minitest::Mock.new
    warden.expect(:authenticate!, true)

    __vc_test_helpers_request.env["warden"] = warden

    with_request_url "/constraints_with_env" do
      render_inline(ControllerInlineComponent.new(message: "request.env is valid"))
    end

    assert_selector("div", text: "request.env is valid")
  end
end
