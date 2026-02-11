# frozen_string_literal: true

require "test_helper"

class TestHelperTest < ViewComponent::TestCase
  def test_with_request_url_inside_slots_path
    with_request_url "/slots" do
      render_inline(CurrentPageComponent.new)
    end

    assert_selector("div", text: "Inside /slots (GET /slots)")
  end

  def test_with_request_url_outside_slots_path
    with_request_url "/" do
      render_inline(CurrentPageComponent.new)
    end

    assert_selector("div", text: "Outside /slots (GET /)")
  end

  def test_with_request_url_specifying_method
    with_request_url "/create", method: "POST" do
      render_inline(CurrentPageComponent.new)
    end

    assert_selector("div", text: "Outside /slots (POST /create)")
  end

  def test_with_request_url_under_constraint
    warden = Minitest::Mock.new
    warden.expect(:authenticate!, true)

    vc_test_request.env["warden"] = warden

    with_request_url "/constraints_with_env" do
      render_inline(ControllerInlineComponent.new(message: "request.env is valid"))
    end

    assert_selector("div", text: "request.env is valid")
  end

  def test_vc_test_controller_exists
    assert vc_test_controller.is_a?(ActionController::Base)
  end

  def test_vc_test_view_context_is_shared_reference
    builder = ActionView::Helpers::FormBuilder.new(nil, Object.new, vc_test_view_context, {})
    render_inline(CustomFormBuilderComponent.new(builder: builder)) { "Label content" }
    assert_selector("label[for=foo]", text: "Label content")
  end

  def test_with_request_url_specifying_http_protocol
    with_request_url "/products", protocol: "http" do
      render_inline(ProtocolComponent.new)
    end

    assert_selector(".protocol", text: "Protocol: http, SSL: false")
  end

  def test_with_request_url_specifying_https_protocol
    with_request_url "/products", protocol: "https" do
      render_inline(ProtocolComponent.new)
    end

    assert_selector(".protocol", text: "Protocol: https, SSL: true")
  end

  def test_with_request_url_restores_original_protocol
    # Store original protocol
    original_scheme = vc_test_request.scheme

    with_request_url "/products", protocol: "https" do
      assert_equal "https", vc_test_request.scheme
    end

    # Verify original protocol is restored
    assert_equal original_scheme, vc_test_request.scheme
  end

  def test_with_request_url_with_protocol_and_host
    with_request_url "/products", protocol: "https", host: "secure.example.com" do
      render_inline(ProtocolComponent.new)
    end

    assert_selector(".protocol", text: "Protocol: https, SSL: true")
  end
end
