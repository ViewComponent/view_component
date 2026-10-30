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

  def test_with_controller_class_replaces_and_restores_the_view_context
    original_controller = vc_test_controller
    original_context = vc_test_view_context

    with_controller_class(CustomTestControllerController) do
      assert_instance_of CustomTestControllerController, vc_test_view_context.controller
      render_inline(CustomTestControllerComponent.new)
      assert_text "foo"
    end

    assert_same original_controller, vc_test_controller
    assert_same original_context, vc_test_view_context
  end

  def test_with_controller_class_restores_the_view_context_after_an_error
    original_controller = vc_test_controller
    original_context = vc_test_view_context

    assert_raises(RuntimeError) do
      with_controller_class(CustomTestControllerController) do
        vc_test_view_context
        raise "restore controller"
      end
    end

    assert_same original_controller, vc_test_controller
    assert_same original_context, vc_test_view_context
  end

  def test_with_request_url_refreshes_existing_controller_parameters
    controller = vc_test_controller
    original_params = controller.params

    %w[first second].each do |filter|
      with_request_url("/products?filter=#{filter}") do
        render_in_view_context { params[:filter] }
        assert_text filter
        assert_same controller, vc_test_controller
      end

      assert_same original_params, controller.params
    end
  end

  def test_with_request_url_restores_parameters_after_nested_blocks_and_errors
    controller = vc_test_controller
    original_params = controller.params

    with_request_url("/products?filter=outer") do
      assert_equal "outer", controller.params[:filter]

      assert_raises(RuntimeError) do
        with_request_url("/slots?filter=inner") do
          assert_equal "inner", controller.params[:filter]
          raise "restore parameters"
        end
      end

      assert_equal "outer", controller.params[:filter]
    end

    assert_same original_params, controller.params
  end

  def test_with_request_url_specifying_http_protocol
    with_request_url "/products", protocol: :http do
      render_inline(ProtocolComponent.new)
    end

    assert_selector(".protocol", text: "Protocol: http, SSL: false")
  end

  def test_with_request_url_specifying_https_protocol
    with_request_url "/products", protocol: :https do
      render_inline(ProtocolComponent.new)
    end

    assert_selector(".protocol", text: "Protocol: https, SSL: true")
  end

  def test_with_request_url_restores_original_protocol
    # Store original protocol
    original_scheme = vc_test_request.scheme

    with_request_url "/products", protocol: :https do
      assert_equal "https", vc_test_request.scheme
    end

    # Verify original protocol is restored
    assert_equal original_scheme, vc_test_request.scheme
  end

  def test_with_request_url_with_protocol_and_host
    with_request_url "/products", protocol: :https, host: "secure.example.com" do
      render_inline(ProtocolComponent.new)
    end

    assert_selector(".protocol", text: "Protocol: https, SSL: true")
  end

  def test_with_request_url_restores_full_paths_after_nested_blocks_and_errors
    request = vc_test_request
    original_fullpath = request.fullpath
    original_original_fullpath = request.original_fullpath

    with_request_url("/products?outer=true") do
      assert_raises(RuntimeError) do
        with_request_url("/slots?inner=true") do
          assert_equal "/slots?inner=true", request.fullpath
          assert_equal "/slots?inner=true", request.original_fullpath
          raise "restore request"
        end
      end

      assert_equal "/products?outer=true", request.fullpath
      assert_equal "/products?outer=true", request.original_fullpath
    end

    assert_equal original_fullpath, request.fullpath
    assert_equal original_original_fullpath, request.original_fullpath
  end
end
