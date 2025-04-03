# frozen_string_literal: true

require "test_helper"

class NilDescribedClassTest < ViewComponent::TestCase
  def setup
    ViewComponent::Preview.__vc_load_previews
  end

  def described_class
    nil
  end

  def test_render_preview
    assert_raises(ArgumentError) do
      render_preview(:default)
    end
  end
end
