# frozen_string_literal: true

require "test_helper"
include PreviewHelper

class PreviewHelperTest < ActiveSupport::TestCase
  def test_returns_the_language_from_the_file_extention
    template = Minitest::Mock.new
    template.expect :identifier, "template.html.erb"

    assert_equal(PreviewHelper.prism_language_name(template: template), "erb")
  end

  def test_returns_fallback_language_if_file_extention_unknown
    template = Minitest::Mock.new
    template.expect :identifier, "template.html.slim"

    assert_equal(PreviewHelper.prism_language_name(template: template), "ruby")
  end
end
