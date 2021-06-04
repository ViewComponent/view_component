require "test_helper"

class SharedViewComponentsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Shared::ViewComponents::VERSION::STRING
  end
end
