# frozen_string_literal: true

require "test_helper"

class ConflictingPrivateApiTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.load_previews
  end

  def controller
  end

  def request
  end

  def build_controller(_)
  end

  def preview_class
  end

  def test_with_conflicting_private_api
    render_inline(ErbComponent.new(message: "foo"))
    assert_content("foo")
  end

  def test_with_conflicting_request
    with_request_url("/") do
      render_inline(ErbComponent.new(message: "foo"))
      assert_content("foo")
    end
  end

  def test_with_conflicting_preview_class
    render_preview(:default)

    assert_selector("div", text: "hello,world!")
  end
end
